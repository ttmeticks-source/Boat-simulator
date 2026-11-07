import AppKit
import SpriteKit
import SwiftUI

@main
struct BoatSimulatorApp: App {
    var body: some Scene {
        WindowGroup { SandboxView().frame(minWidth: 980, minHeight: 640) }
            .windowStyle(HiddenTitleBarWindowStyle())
    }
}

struct SandboxView: View {
    @State private var resetID = UUID()
    @State private var paused = false
    @State private var tool = "Impact"
    @State private var wave = false
    private let tools = ["Impact", "Cut", "Repair", "Fire", "Extinguish"]
    var body: some View {
        ZStack {
            PhysicsView(resetID: resetID, paused: paused, tool: tool, wave: wave)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("FLOATLAB").font(.system(size: 20, weight: .black, design: .rounded)).tracking(3)
                        Text("2D SHIP PHYSICS SANDBOX").font(.system(size: 9, weight: .bold, design: .monospaced)).tracking(2).foregroundColor(.cyan)
                    }
                    Spacer()
                    ForEach(tools, id: \.self) { item in
                        Button(item.uppercased()) { tool = item }
                            .buttonStyle(ToolButton(active: tool == item))
                    }
                    Button("WAVE") { wave.toggle() }.buttonStyle(ToolButton(active: wave))
                    Button(paused ? "PLAY" : "PAUSE") { paused.toggle() }.buttonStyle(ToolButton(active: paused))
                    Button("RESET") { resetID = UUID(); paused = false; wave = false }.buttonStyle(ToolButton(active: false))
                }.padding(.horizontal, 18).padding(.vertical, 15)
                Spacer()
                HStack {
                    Text("TOOL: \(tool.uppercased())")
                    Spacer()
                    Text("CLICK / DRAG THE SHIP TO INTERACT")
                    Spacer()
                    Text("PARTICLE + SPRING STRUCTURE")
                }.font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.75))
                    .padding(14).background(.black.opacity(0.55))
            }
        }.preferredColorScheme(.dark)
    }
}

struct ToolButton: ButtonStyle {
    let active: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 9, weight: .heavy, design: .monospaced))
            .padding(.horizontal, 10).padding(.vertical, 9)
            .background(active ? Color.cyan.opacity(0.28) : Color.white.opacity(0.07))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(active ? Color.cyan : Color.white.opacity(0.2)))
            .foregroundColor(active ? .cyan : .white)
            .opacity(configuration.isPressed ? 0.65 : 1)
    }
}

struct PhysicsView: NSViewRepresentable {
    let resetID: UUID
    let paused: Bool
    let tool: String
    let wave: Bool
    func makeNSView(context: Context) -> SKView {
        let view = SKView()
        view.ignoresSiblingOrder = true
        view.showsFPS = false
        view.showsNodeCount = false
        let scene = ShipScene(size: CGSize(width: 1200, height: 760))
        scene.scaleMode = .resizeFill
        view.presentScene(scene)
        context.coordinator.scene = scene
        return view
    }
    func updateNSView(_ view: SKView, context: Context) {
        context.coordinator.scene?.selectedTool = tool
        context.coordinator.scene?.paused = paused
        if context.coordinator.resetID != resetID {
            let scene = ShipScene(size: view.bounds.size)
            scene.scaleMode = .resizeFill
            scene.selectedTool = tool
            scene.paused = paused
            view.presentScene(scene)
            context.coordinator.scene = scene
            context.coordinator.resetID = resetID
        }
        if wave && !context.coordinator.lastWave {
            context.coordinator.scene?.triggerWave()
        }
        context.coordinator.lastWave = wave
    }
    func makeCoordinator() -> Coordinator { Coordinator() }
    final class Coordinator {
        weak var scene: ShipScene?
        var resetID = UUID()
        var lastWave = false
    }
}

final class ShipScene: SKScene {
    var selectedTool = "Impact"
    var paused = false { didSet { isPaused = paused } }
    private var particles: [HullParticle] = []
    private var springs: [HullSpring] = []
    private var waterY: CGFloat = 245
    private var lastUpdate: TimeInterval = 0
    private var waveEnergy: CGFloat = 0
    private var waterNodes: [SKShapeNode] = []
    private var status: SKLabelNode!
    private var fireNodes: [SKShapeNode] = []
    private var leakCount = 0
    private var flood = 0.0
    private var heat = 0.0
    private var dragging = false
    private var lastToolPoint = CGPoint.zero

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.018, green: 0.045, blue: 0.075, alpha: 1)
        buildWorld()
        buildShip()
    }

    private func buildWorld() {
        let sky = SKShapeNode(rect: CGRect(x: 0, y: waterY, width: size.width, height: size.height - waterY))
        sky.fillColor = SKColor(red: 0.025, green: 0.10, blue: 0.15, alpha: 1)
        sky.strokeColor = .clear; sky.zPosition = -20; addChild(sky)
        let seabed = SKShapeNode(rect: CGRect(x: 0, y: 0, width: size.width, height: waterY - 8))
        seabed.fillColor = SKColor(red: 0.12, green: 0.13, blue: 0.12, alpha: 1)
        seabed.strokeColor = .clear; seabed.zPosition = -18; addChild(seabed)
        for i in 0..<18 {
            let line = SKShapeNode()
            line.strokeColor = SKColor(red: 0.25, green: 0.72, blue: 0.82, alpha: 0.12)
            line.lineWidth = 1
            let y = waterY + CGFloat(i) * 22
            line.path = CGPath(roundedRect: CGRect(x: 0, y: y, width: size.width, height: 0.5), cornerWidth: 0, cornerHeight: 0, transform: nil)
            line.zPosition = -15; addChild(line)
        }
        for i in 0..<7 {
            let wave = SKShapeNode()
            wave.strokeColor = SKColor.cyan.withAlphaComponent(0.32)
            wave.lineWidth = 1.2; wave.zPosition = 8
            addChild(wave); waterNodes.append(wave)
        }
        status = SKLabelNode(fontNamed: "Menlo-Bold")
        status.fontSize = 11; status.fontColor = .white
        status.horizontalAlignmentMode = .left; status.position = CGPoint(x: 24, y: size.height - 74)
        status.zPosition = 80; addChild(status)
    }

    private func buildShip() {
        particles.removeAll(); springs.removeAll()
        let cx = size.width * 0.5
        let baseY = waterY + 62
        let count = 25
        for i in 0..<count {
            let t = CGFloat(i) / CGFloat(count - 1)
            let x = cx - 310 + t * 620
            let taper = abs(t - 0.5) * 2
            let y = baseY + 42 - taper * 34
            addParticle(CGPoint(x: x, y: y), mass: 1.7, radius: 8, kind: .steel)
            addParticle(CGPoint(x: x, y: y + 42), mass: 1.4, radius: 6, kind: .deck)
            if i > 0 {
                connect(i * 2 - 2, i * 2, stiffness: 0.92)
                connect(i * 2 - 1, i * 2 + 1, stiffness: 0.88)
                connect(i * 2 - 2, i * 2 + 1, stiffness: 0.58)
                connect(i * 2 - 1, i * 2, stiffness: 0.58)
            }
            connect(i * 2, i * 2 + 1, stiffness: 0.95)
        }
        for i in stride(from: 0, to: count - 2, by: 2) {
            connect(i, i + 4, stiffness: 0.34)
            connect(i + 1, i + 5, stiffness: 0.30)
        }
        // Cabin, smokestacks and deck details are attached to the spring hull.
        let cabin = SKShapeNode(rectOf: CGSize(width: 115, height: 52), cornerRadius: 5)
        cabin.fillColor = SKColor(red: 0.78, green: 0.79, blue: 0.75, alpha: 1)
        cabin.strokeColor = .white; cabin.lineWidth = 1.5
        cabin.position = CGPoint(x: cx + 65, y: baseY + 91); cabin.zPosition = 5; addChild(cabin)
        let windows = SKShapeNode(rectOf: CGSize(width: 95, height: 17), cornerRadius: 2)
        windows.fillColor = SKColor(red: 0.025, green: 0.13, blue: 0.18, alpha: 1)
        windows.strokeColor = .clear; windows.position = CGPoint(x: cx + 65, y: baseY + 98); windows.zPosition = 6; addChild(windows)
        for x in [cx - 115, cx - 58] {
            let stack = SKShapeNode(rectOf: CGSize(width: 23, height: 55), cornerRadius: 5)
            stack.fillColor = SKColor(red: 0.82, green: 0.22, blue: 0.07, alpha: 1)
            stack.strokeColor = .black; stack.position = CGPoint(x: x, y: baseY + 89); stack.zPosition = 5; addChild(stack)
        }
        let name = SKLabelNode(fontNamed: "Menlo-Bold")
        name.text = "F L O A T L A B"; name.fontSize = 10; name.fontColor = .white
        name.position = CGPoint(x: cx, y: baseY + 13); name.zPosition = 7; addChild(name)
    }

    private enum Material { case steel, deck }
    private func addParticle(_ p: CGPoint, mass: CGFloat, radius: CGFloat, kind: Material) {
        let node = SKShapeNode(circleOfRadius: radius)
        node.fillColor = kind == .steel ? SKColor(red: 0.64, green: 0.16, blue: 0.12, alpha: 1) : SKColor(white: 0.72, alpha: 1)
        node.strokeColor = SKColor(white: 0.95, alpha: 0.65); node.lineWidth = 1
        node.position = p; node.zPosition = 4; addChild(node)
        particles.append(HullParticle(position: p, previous: p, mass: mass, radius: radius, node: node, material: kind))
    }
    private func connect(_ a: Int, _ b: Int, stiffness: CGFloat) {
        guard a < particles.count, b < particles.count else { return }
        let line = SKShapeNode()
        line.strokeColor = SKColor(red: 0.76, green: 0.27, blue: 0.19, alpha: 1)
        line.lineWidth = 5; line.zPosition = 2; addChild(line)
        springs.append(HullSpring(a: a, b: b, rest: distance(particles[a].position, particles[b].position), stiffness: stiffness, node: line))
    }

    override func update(_ currentTime: TimeInterval) {
        guard lastUpdate != 0 else { lastUpdate = currentTime; return }
        let dt = CGFloat(min(currentTime - lastUpdate, 1.0 / 30.0))
        lastUpdate = currentTime
        guard dt > 0 else { return }
        waveEnergy *= 0.985
        let time = CGFloat(currentTime)
        for i in particles.indices {
            var p = particles[i]
            let old = p.position
            var velocity = (p.position - p.previous) * 0.992
            var acceleration = CGVector(dx: 0, dy: -440)
            let submersion = max(0, min(1, (waterY + 20 - p.position.y) / 34))
            acceleration.dy += submersion * (p.mass > 1.5 ? 710 : 570)
            acceleration.dx += sin(time * 1.3 + p.position.x * 0.008) * (submersion * 9 + waveEnergy * 24)
            acceleration.dy += sin(time * 1.7 + p.position.x * 0.012) * waveEnergy * 35
            velocity = velocity + acceleration * (dt * dt)
            p.previous = old
            p.position = p.position + velocity
            p.position.x = max(20, min(size.width - 20, p.position.x))
            if p.position.y < 20 { p.position.y = 20; p.previous.y = p.position.y }
            particles[i] = p
        }
        for _ in 0..<5 {
            for spring in springs {
                guard spring.a < particles.count, spring.b < particles.count else { continue }
                let delta = particles[spring.b].position - particles[spring.a].position
                let len = max(0.001, hypot(delta.dx, delta.dy))
                let correction = delta * ((len - spring.rest) / len * spring.stiffness * 0.5)
                particles[spring.a].position = particles[spring.a].position + correction
                particles[spring.b].position = particles[spring.b].position - correction
            }
        }
        for i in particles.indices {
            particles[i].node.position = particles[i].position
        }
        for s in springs {
            let path = CGMutablePath()
            path.move(to: particles[s.a].position); path.addLine(to: particles[s.b].position)
            s.node.path = path
        }
        updateWater(time: time)
        updateFire(dt: dt)
        let submerged = particles.filter { $0.position.y < waterY }.count
        status.text = "HULL NODES \(particles.count)   BROKEN LINKS \(leakCount)   WATER INTAKE \(Int(flood))%   HEAT \(Int(heat))%   UNDERWATER \(submerged)"
        if flood > 0 { flood = min(100, flood + Double(leakCount) * Double(dt) * 1.5) }
    }

    private func updateWater(time: CGFloat) {
        for (i, line) in waterNodes.enumerated() {
            let path = CGMutablePath()
            let yBase = waterY + CGFloat(i) * 2
            path.move(to: CGPoint(x: 0, y: yBase))
            for x in stride(from: CGFloat(0), through: size.width, by: 24) {
                let y = yBase + sin(x * 0.012 + time * 1.5) * (2 + waveEnergy * 14)
                path.addLine(to: CGPoint(x: x, y: y))
            }
            line.path = path
        }
    }
    private func updateFire(dt: CGFloat) {
        guard heat > 0 else { return }
        heat = max(0, heat - Double(dt) * 2.2)
        if Int.random(in: 0..<4) == 0, let p = particles.filter({ $0.position.y > waterY }).randomElement() {
            let flame = SKShapeNode(circleOfRadius: CGFloat.random(in: 3...8))
            flame.fillColor = SKColor.orange.withAlphaComponent(0.8); flame.strokeColor = .clear
            flame.position = p.position; flame.zPosition = 12; addChild(flame)
            flame.run(.sequence([.group([.moveBy(x: CGFloat.random(in: -12...12), y: 30, duration: 0.55), .fadeOut(withDuration: 0.55)]), .removeFromParent()]))
        }
    }

    func triggerWave() { waveEnergy = min(3, waveEnergy + 2.4) }

    private func hit(_ point: CGPoint) {
        switch selectedTool {
        case "Impact":
            for i in particles.indices where distance(particles[i].position, point) < 38 {
                let d = particles[i].position - point
                let n = max(1, hypot(d.dx, d.dy))
                particles[i].previous = particles[i].position - d * (95 / n)
            }
        case "Cut":
            let before = springs.count
            springs.removeAll { s in
                let midpoint = (particles[s.a].position + particles[s.b].position) * 0.5
                if distance(midpoint, point) < 24 { s.node.removeFromParent(); return true }
                return false
            }
            let removed = before - springs.count
            leakCount += removed
        case "Repair":
            // Reconnect nearby separated nodes with a fresh structural link.
            let nearby = particles.indices.filter { distance(particles[$0].position, point) < 55 }
            if nearby.count >= 2 {
                let a = nearby[0], b = nearby[nearby.count - 1]
                if a != b { connect(a, b, stiffness: 0.72); leakCount = max(0, leakCount - 1) }
            }
        case "Fire": heat = min(100, heat + 28)
        case "Extinguish": heat = max(0, heat - 45)
        default: break
        }
        let ring = SKShapeNode(circleOfRadius: 24)
        ring.strokeColor = .cyan.withAlphaComponent(0.8); ring.lineWidth = 2
        ring.fillColor = .clear; ring.position = point; ring.zPosition = 30; addChild(ring)
        ring.run(.sequence([.group([.scale(to: 2.1, duration: 0.25), .fadeOut(withDuration: 0.25)]), .removeFromParent()]))
    }

    override func mouseDown(with event: NSEvent) {
        dragging = true
        lastToolPoint = event.location(in: self)
        hit(lastToolPoint)
    }
    override func mouseDragged(with event: NSEvent) {
        let point = event.location(in: self)
        if selectedTool == "Impact" { hit(point) }
        lastToolPoint = point
    }
    override func mouseUp(with event: NSEvent) { dragging = false }

    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat { hypot(a.x - b.x, a.y - b.y) }
}

private struct HullParticle {
    var position: CGPoint
    var previous: CGPoint
    let mass: CGFloat
    let radius: CGFloat
    let node: SKShapeNode
    let material: Any
}
private struct HullSpring {
    let a: Int
    let b: Int
    let rest: CGFloat
    let stiffness: CGFloat
    let node: SKShapeNode
}
private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat { hypot(a.x - b.x, a.y - b.y) }
private func + (lhs: CGPoint, rhs: CGVector) -> CGPoint { CGPoint(x: lhs.x + rhs.dx, y: lhs.y + rhs.dy) }
private func - (lhs: CGPoint, rhs: CGPoint) -> CGVector { CGVector(dx: lhs.x - rhs.x, dy: lhs.y - rhs.y) }
private func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint { CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y) }
private func - (lhs: CGPoint, rhs: CGVector) -> CGPoint { CGPoint(x: lhs.x - rhs.dx, y: lhs.y - rhs.dy) }
private func * (lhs: CGVector, rhs: CGFloat) -> CGVector { CGVector(dx: lhs.dx * rhs, dy: lhs.dy * rhs) }
private func * (lhs: CGVector, rhs: CGFloat) -> CGVector { CGVector(dx: lhs.dx * rhs, dy: lhs.dy * rhs) }
private func + (lhs: CGVector, rhs: CGVector) -> CGVector { CGVector(dx: lhs.dx + rhs.dx, dy: lhs.dy + rhs.dy) }
private func * (lhs: CGPoint, rhs: CGFloat) -> CGVector { CGVector(dx: lhs.x * rhs, dy: lhs.y * rhs) }
private func - (lhs: CGPoint, rhs: CGVector) -> CGPoint { CGPoint(x: lhs.x - rhs.dx, y: lhs.y - rhs.dy) }
