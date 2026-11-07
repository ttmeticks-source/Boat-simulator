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
    private let tools = ["Impact", "Cut", "Repair", "Flood", "Pump", "Fire", "Extinguish"]

    var body: some View {
        ZStack {
            PhysicsView(resetID: resetID, paused: paused, tool: tool, wave: wave)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    ForEach(["File", "Controls", "Tools", "Options", "ShipBuilder", "Help"], id: \.self) { item in
                        Text(item)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(red: 0.16, green: 0.19, blue: 0.22))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                    }
                    Spacer()
                    Text("FLOATLAB  •  SHIP PHYSICS")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color(red: 0.25, green: 0.31, blue: 0.36))
                        .padding(.trailing, 14)
                }
                .frame(height: 30)
                .background(LinearGradient(colors: [Color(white: 0.96), Color(white: 0.82)], startPoint: .top, endPoint: .bottom))
                .overlay(Rectangle().fill(Color(white: 0.55)).frame(height: 1), alignment: .bottom)

                Spacer(minLength: 0)

                HStack(spacing: 7) {
                    ForEach(tools, id: \.self) { item in
                        Button { tool = item } label: {
                            VStack(spacing: 4) {
                                Image(systemName: iconFor(item))
                                    .font(.system(size: 19, weight: .regular))
                                    .frame(height: 23)
                                Text(item.uppercased())
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .frame(width: 66, height: 54)
                        }
                        .buttonStyle(ToolButton(active: tool == item))
                    }
                    Rectangle().fill(Color.black.opacity(0.25)).frame(width: 1, height: 48).padding(.horizontal, 3)
                    Button { wave.toggle() } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "water.waves").font(.system(size: 19))
                            Text("WAVE").font(.system(size: 8, weight: .bold, design: .monospaced))
                        }.frame(width: 58, height: 54)
                    }.buttonStyle(ToolButton(active: wave))
                    Button { paused.toggle() } label: {
                        VStack(spacing: 4) {
                            Image(systemName: paused ? "play.fill" : "pause.fill").font(.system(size: 19))
                            Text(paused ? "PLAY" : "PAUSE").font(.system(size: 8, weight: .bold, design: .monospaced))
                        }.frame(width: 58, height: 54)
                    }.buttonStyle(ToolButton(active: paused))
                    Button { resetID = UUID(); paused = false; wave = false } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "arrow.counterclockwise").font(.system(size: 19))
                            Text("RESET").font(.system(size: 8, weight: .bold, design: .monospaced))
                        }.frame(width: 58, height: 54)
                    }.buttonStyle(ToolButton(active: false))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(colors: [Color(white: 0.74), Color(white: 0.55), Color(white: 0.67)], startPoint: .top, endPoint: .bottom)
                )
                .overlay(Rectangle().fill(Color.white.opacity(0.85)).frame(height: 1), alignment: .top)
                .overlay(Rectangle().fill(Color(white: 0.30)).frame(height: 1), alignment: .bottom)
            }
        }
        .preferredColorScheme(.light)
    }

    private func iconFor(_ item: String) -> String {
        switch item {
        case "Impact": return "hand.point.up.left"
        case "Cut": return "scissors"
        case "Repair": return "wrench.and.screwdriver"
        case "Flood": return "drop.fill"
        case "Pump": return "waterpump.fill"
        case "Fire": return "flame.fill"
        default: return "drop"
        }
    }
}

struct ToolButton: ButtonStyle {
    let active: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(active ? Color(red: 0.05, green: 0.28, blue: 0.52) : Color(red: 0.12, green: 0.15, blue: 0.18))
            .background(
                LinearGradient(
                    colors: active
                        ? [Color(red: 0.82, green: 0.91, blue: 0.98), Color(red: 0.60, green: 0.77, blue: 0.91)]
                        : [Color(white: 0.94), Color(white: 0.73)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(RoundedRectangle(cornerRadius: 3).stroke(active ? Color(red: 0.18, green: 0.38, blue: 0.58) : Color(white: 0.38), lineWidth: 1))
            .overlay(Rectangle().fill(Color.white.opacity(0.75)).frame(height: 1).padding(.horizontal, 3), alignment: .top)
            .shadow(color: .black.opacity(0.18), radius: 1, x: 0, y: 1)
            .opacity(configuration.isPressed ? 0.72 : 1)
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
        context.coordinator.scene?.simulationPaused = paused
        if context.coordinator.resetID != resetID {
            let scene = ShipScene(size: view.bounds.size)
            scene.scaleMode = .resizeFill
            scene.selectedTool = tool
            scene.simulationPaused = paused
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
    var simulationPaused = false { didSet { isPaused = simulationPaused } }
    private var particles: [HullParticle] = []
    private var springs: [HullSpring] = []
    private var waterY: CGFloat = 245
    private var shipArt: SKNode!
    private var hullRedBand: SKShapeNode!
    private var waterBody: SKShapeNode!
    private var cloudNodes: [SKNode] = []
    private var lastUpdate: TimeInterval = 0
    private var waveEnergy: CGFloat = 0
    private var waterNodes: [SKShapeNode] = []
    private var hullSkin: SKShapeNode!
    private var internalWater: SKShapeNode!
    private var cabinLights: [SKShapeNode] = []
    private var status: SKLabelNode!
    private var fireNodes: [SKShapeNode] = []
    private var leakCount = 0
    private var flood = 0.0
    private var heat = 0.0
    private var waterMass: CGFloat = 0
    private var electricalPower = true
    private var simulationTime: CGFloat = 0
    private var dragging = false
    private var lastToolPoint = CGPoint.zero

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.48, green: 0.76, blue: 0.91, alpha: 1)
        waterY = size.height * 0.44
        buildWorld()
        buildShip()
    }

    private func buildWorld() {
        // Bright open sky, distant haze, and a deep blue ocean like the original
        // side-on Floating Sandbox view.
        let sky = SKShapeNode(rect: CGRect(x: 0, y: waterY, width: size.width, height: size.height - waterY))
        sky.fillColor = SKColor(red: 0.48, green: 0.77, blue: 0.93, alpha: 1)
        sky.strokeColor = .clear
        sky.zPosition = -30
        addChild(sky)

        let sunHalo = SKShapeNode(circleOfRadius: 115)
        sunHalo.fillColor = SKColor(red: 1.0, green: 0.97, blue: 0.78, alpha: 0.10)
        sunHalo.strokeColor = .clear
        sunHalo.position = CGPoint(x: size.width * 0.82, y: size.height * 0.80)
        sunHalo.zPosition = -26
        addChild(sunHalo)

        for i in 0..<4 {
            let cloud = makeCloud()
            cloud.position = CGPoint(x: CGFloat([0.17, 0.48, 0.78, 0.91][i]) * size.width,
                                     y: size.height * CGFloat([0.78, 0.88, 0.73, 0.91][i]))
            cloud.setScale(CGFloat([0.78, 1.05, 0.72, 0.55][i]))
            cloud.zPosition = -24
            addChild(cloud)
            cloudNodes.append(cloud)
        }

        waterBody = SKShapeNode(rect: CGRect(x: 0, y: 0, width: size.width, height: waterY))
        waterBody.fillColor = SKColor(red: 0.20, green: 0.58, blue: 0.78, alpha: 1)
        waterBody.strokeColor = .clear
        waterBody.zPosition = -20
        addChild(waterBody)

        for i in 0..<12 {
            let band = SKShapeNode(rect: CGRect(x: 0, y: CGFloat(i) * waterY / 12,
                                                width: size.width, height: waterY / 12 + 1))
            let blend = CGFloat(i) / 11
            band.fillColor = SKColor(red: 0.24 - blend * 0.08,
                                     green: 0.64 - blend * 0.22,
                                     blue: 0.83 - blend * 0.16,
                                     alpha: 0.24)
            band.strokeColor = .clear
            band.zPosition = -19
            addChild(band)
        }

        for i in 0..<4 {
            let line = SKShapeNode()
            line.strokeColor = SKColor(red: 0.83, green: 0.95, blue: 1.0, alpha: 0.22 - CGFloat(i) * 0.035)
            line.lineWidth = i == 0 ? 2.2 : 1
            line.zPosition = 25 + CGFloat(i)
            addChild(line)
            waterNodes.append(line)
        }

        status = SKLabelNode(fontNamed: "Menlo")
        status.fontSize = 10
        status.fontColor = SKColor(red: 0.08, green: 0.20, blue: 0.28, alpha: 0.92)
        status.horizontalAlignmentMode = .left
        status.position = CGPoint(x: 18, y: size.height - 52)
        status.zPosition = 80
        addChild(status)
    }

    private func makeCloud() -> SKNode {
        let cloud = SKNode()
        let puffs: [(CGFloat, CGFloat, CGFloat)] = [
            (-28, 0, 19), (-10, 9, 24), (13, 6, 21), (32, -1, 15), (0, -5, 20)
        ]
        for (x, y, radius) in puffs {
            let puff = SKShapeNode(circleOfRadius: radius)
            puff.fillColor = SKColor(white: 1, alpha: 0.78)
            puff.strokeColor = SKColor(white: 1, alpha: 0.35)
            puff.lineWidth = 1
            puff.position = CGPoint(x: x, y: y)
            cloud.addChild(puff)
        }
        return cloud
    }

    private func addShipPolygon(_ points: [CGPoint], fill: SKColor, stroke: SKColor = .clear,
                                width: CGFloat = 1, z: CGFloat = 1) -> SKShapeNode {
        let path = CGMutablePath()
        guard let first = points.first else { return SKShapeNode() }
        path.move(to: first)
        for point in points.dropFirst() { path.addLine(to: point) }
        path.closeSubpath()
        let node = SKShapeNode(path: path)
        node.fillColor = fill
        node.strokeColor = stroke
        node.lineWidth = width
        node.zPosition = z
        shipArt.addChild(node)
        return node
    }

    private func addShipRect(_ width: CGFloat, _ height: CGFloat, _ x: CGFloat, _ y: CGFloat,
                             _ fill: SKColor, _ stroke: SKColor = .clear,
                             _ radius: CGFloat = 0, _ z: CGFloat = 1) -> SKShapeNode {
        let node = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: radius)
        node.position = CGPoint(x: x, y: y)
        node.fillColor = fill
        node.strokeColor = stroke
        node.lineWidth = 1
        node.zPosition = z
        shipArt.addChild(node)
        return node
    }

    private func addShipLine(_ points: [CGPoint], _ color: SKColor, _ width: CGFloat, _ z: CGFloat = 1) {
        guard let first = points.first else { return }
        let path = CGMutablePath()
        path.move(to: first)
        for point in points.dropFirst() { path.addLine(to: point) }
        let line = SKShapeNode(path: path)
        line.strokeColor = color
        line.lineWidth = width
        line.lineCap = .round
        line.lineJoin = .round
        line.zPosition = z
        shipArt.addChild(line)
    }

    private func buildShip() {
        particles.removeAll()
        springs.removeAll()
        let cx = size.width * 0.5

        hullSkin = SKShapeNode()
        hullSkin.fillColor = SKColor(red: 0.035, green: 0.075, blue: 0.12, alpha: 1)
        hullSkin.strokeColor = SKColor(red: 0.015, green: 0.035, blue: 0.06, alpha: 1)
        hullSkin.lineWidth = 3
        hullSkin.zPosition = 3
        addChild(hullSkin)

        hullRedBand = SKShapeNode()
        hullRedBand.fillColor = SKColor(red: 0.58, green: 0.16, blue: 0.105, alpha: 1)
        hullRedBand.strokeColor = SKColor(red: 0.28, green: 0.075, blue: 0.055, alpha: 1)
        hullRedBand.lineWidth = 1.5
        hullRedBand.zPosition = 4
        addChild(hullRedBand)

        shipArt = SKNode()
        shipArt.position = CGPoint(x: cx, y: waterY - 35)
        shipArt.zPosition = 8
        addChild(shipArt)

        // Two longitudinal particle rows form the keel/deck structure.
        // The lower row has a shallow ship-shaped keel curve; the upper row
        // forms the sheer line along the deck.
        let count = 41
        for i in 0..<count {
            let t = CGFloat(i) / CGFloat(count - 1)
            let x = cx - 310 + t * 620
            let taper = abs(t - 0.5) * 2
            let bottomY = waterY - 35 + taper * 21
            let deckY = waterY + 38 + taper * 8
            addParticle(CGPoint(x: x, y: bottomY), mass: 2.1, radius: 2, kind: .steel)
            addParticle(CGPoint(x: x, y: deckY), mass: 1.7, radius: 2, kind: .deck)
            if i > 0 {
                connect(i * 2 - 2, i * 2, stiffness: 0.94)
                connect(i * 2 - 1, i * 2 + 1, stiffness: 0.92)
                connect(i * 2 - 2, i * 2 + 1, stiffness: 0.62)
                connect(i * 2 - 1, i * 2, stiffness: 0.62)
            }
            connect(i * 2, i * 2 + 1, stiffness: 0.96)
        }
        for i in stride(from: 0, to: count - 2, by: 2) {
            connect(i, i + 4, stiffness: 0.38)
            connect(i + 1, i + 5, stiffness: 0.34)
        }

        // A custom passenger liner silhouette, built from individually
        // shaded decks, windows, railings, lifeboats, funnels and rigging.
        let ivory = SKColor(red: 0.88, green: 0.87, blue: 0.79, alpha: 1)
        let cream = SKColor(red: 0.96, green: 0.94, blue: 0.86, alpha: 1)
        let shadow = SKColor(red: 0.28, green: 0.31, blue: 0.32, alpha: 1)
        let glass = SKColor(red: 0.045, green: 0.16, blue: 0.23, alpha: 1)
        let brass = SKColor(red: 0.76, green: 0.48, blue: 0.15, alpha: 1)

        // Hull sheer, bow flare and stern counter.
        addShipPolygon([
            CGPoint(x: -310, y: 37), CGPoint(x: -292, y: 22), CGPoint(x: -240, y: 9),
            CGPoint(x: -145, y: 1), CGPoint(x: 0, y: -2), CGPoint(x: 160, y: 2),
            CGPoint(x: 260, y: 12), CGPoint(x: 306, y: 35), CGPoint(x: 292, y: 49),
            CGPoint(x: -285, y: 49)
        ], fill: SKColor(red: 0.045, green: 0.09, blue: 0.13, alpha: 1),
           stroke: SKColor(red: 0.015, green: 0.035, blue: 0.05, alpha: 1), width: 2, z: 2)
        addShipPolygon([
            CGPoint(x: -287, y: 23), CGPoint(x: -235, y: 5), CGPoint(x: -145, y: -3),
            CGPoint(x: 0, y: -8), CGPoint(x: 160, y: -3), CGPoint(x: 260, y: 8),
            CGPoint(x: 300, y: 31), CGPoint(x: 288, y: 35), CGPoint(x: 250, y: 22),
            CGPoint(x: 150, y: 12), CGPoint(x: 0, y: 7), CGPoint(x: -150, y: 12),
            CGPoint(x: -240, y: 23)
        ], fill: SKColor(red: 0.58, green: 0.15, blue: 0.10, alpha: 1),
           stroke: SKColor(red: 0.30, green: 0.07, blue: 0.05, alpha: 1), width: 1, z: 3)
        addShipLine([CGPoint(x: -294, y: 39), CGPoint(x: -235, y: 29), CGPoint(x: -145, y: 23),
                     CGPoint(x: 0, y: 21), CGPoint(x: 160, y: 25), CGPoint(x: 265, y: 37),
                     CGPoint(x: 302, y: 48)], SKColor(red: 0.82, green: 0.78, blue: 0.65, alpha: 1), 2, 5)

        // Broad lower promenade deck and progressively narrower upper decks.
        addShipPolygon([
            CGPoint(x: -274, y: 48), CGPoint(x: 267, y: 48), CGPoint(x: 289, y: 57),
            CGPoint(x: 270, y: 80), CGPoint(x: -263, y: 80), CGPoint(x: -285, y: 67)
        ], fill: ivory, stroke: shadow, width: 1.2, z: 7)
        addShipPolygon([
            CGPoint(x: -250, y: 80), CGPoint(x: 245, y: 80), CGPoint(x: 229, y: 106),
            CGPoint(x: -234, y: 106), CGPoint(x: -260, y: 93)
        ], fill: cream, stroke: shadow, width: 1, z: 8)
        addShipPolygon([
            CGPoint(x: -202, y: 106), CGPoint(x: 216, y: 106), CGPoint(x: 194, y: 132),
            CGPoint(x: -185, y: 132), CGPoint(x: -214, y: 120)
        ], fill: ivory, stroke: shadow, width: 1, z: 9)
        addShipPolygon([
            CGPoint(x: 90, y: 132), CGPoint(x: 204, y: 132), CGPoint(x: 190, y: 156),
            CGPoint(x: 103, y: 156), CGPoint(x: 82, y: 145)
        ], fill: cream, stroke: shadow, width: 1, z: 10)
        addShipRect(126, 10, 135, 158, SKColor(red: 0.82, green: 0.82, blue: 0.77, alpha: 1), shadow, 2, 11)
        addShipRect(82, 8, 144, 169, ivory, shadow, 2, 11)

        // Continuous deck stripe and metal railings.
        let railingYs: [CGFloat] = [52, 81, 107, 133, 157]
        for y in railingYs {
            addShipLine([CGPoint(x: -270, y: y), CGPoint(x: 270, y: y)], SKColor(red: 0.42, green: 0.43, blue: 0.41, alpha: 0.85), 1, 12)
        }
        for x in stride(from: CGFloat(-260), through: CGFloat(260), by: CGFloat(9)) {
            addShipLine([CGPoint(x: x, y: 81), CGPoint(x: x, y: 89)], SKColor(white: 0.55, alpha: 0.75), 0.7, 12)
        }

        // Long rows of dark portholes and glazed passenger windows.
        for i in 0..<45 {
            let x = -246 + CGFloat(i) * 11.2
            addShipRect(7.2, 9, x, 67, glass, SKColor(white: 0.65, alpha: 0.7), 1, 13)
            if i < 41 {
                addShipRect(7.0, 9, -224 + CGFloat(i) * 11.1, 94, glass, SKColor(white: 0.68, alpha: 0.7), 1, 13)
            }
            if i < 34 {
                addShipRect(7.0, 9, -184 + CGFloat(i) * 11.1, 120, glass, SKColor(white: 0.68, alpha: 0.7), 1, 14)
            }
        }
        for i in 0..<24 {
            let x = -156 + CGFloat(i) * 13.2
            addShipRect(8, 8, x, 148, glass, SKColor(white: 0.65, alpha: 0.6), 1, 12)
        }
        for i in 0..<34 {
            let x = -220 + CGFloat(i) * 13.1
            let porthole = SKShapeNode(circleOfRadius: 3.1)
            porthole.fillColor = SKColor(red: 0.02, green: 0.06, blue: 0.09, alpha: 1)
            porthole.strokeColor = SKColor(white: 0.72, alpha: 0.55)
            porthole.lineWidth = 0.8
            porthole.position = CGPoint(x: x, y: 37)
            porthole.zPosition = 8
            shipArt.addChild(porthole)
        }

        // Lifeboats with canvas covers and davits.
        for i in 0..<8 {
            let x = -205 + CGFloat(i) * 58
            addShipLine([CGPoint(x: x - 8, y: 85), CGPoint(x: x - 13, y: 101)], shadow, 1, 13)
            addShipLine([CGPoint(x: x + 8, y: 85), CGPoint(x: x + 13, y: 101)], shadow, 1, 13)
            addShipRect(31, 8, x, 101, SKColor(red: 0.67, green: 0.62, blue: 0.49, alpha: 1), shadow, 4, 14)
            addShipRect(24, 4, x, 105, SKColor(red: 0.93, green: 0.88, blue: 0.72, alpha: 1), .clear, 2, 15)
        }

        // Four ochre funnels, black caps, red bases, and dark smoke outlets.
        let funnelPositions: [CGFloat] = [-130, -48, 36, 118]
        for (i, x) in funnelPositions.enumerated() {
            let funnelHeight: CGFloat = i == 1 ? 55 : 50
            addShipRect(25, funnelHeight, x, 174 + funnelHeight * 0.18, brass,
                        SKColor(red: 0.28, green: 0.20, blue: 0.10, alpha: 1), 4, 16)
            addShipRect(29, 8, x, 174 + funnelHeight * 0.18 + funnelHeight * 0.5 - 2,
                        SKColor(red: 0.08, green: 0.09, blue: 0.10, alpha: 1), .clear, 2, 17)
            addShipRect(25, 6, x, 150, SKColor(red: 0.55, green: 0.13, blue: 0.09, alpha: 1), .clear, 1, 15)
            addShipRect(7, 8, x, 174 + funnelHeight * 0.18 + funnelHeight * 0.5 + 3,
                        SKColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1), .clear, 1, 18)
        }

        // Forward and aft masts, stays and radio aerials.
        addShipLine([CGPoint(x: -247, y: 86), CGPoint(x: -247, y: 218)], SKColor(white: 0.22, alpha: 1), 3, 16)
        addShipLine([CGPoint(x: 253, y: 83), CGPoint(x: 253, y: 205)], SKColor(white: 0.22, alpha: 1), 3, 16)
        addShipLine([CGPoint(x: -247, y: 216), CGPoint(x: -294, y: 52)], shadow, 1, 15)
        addShipLine([CGPoint(x: -247, y: 216), CGPoint(x: -45, y: 145)], shadow, 1, 15)
        addShipLine([CGPoint(x: 253, y: 204), CGPoint(x: 295, y: 53)], shadow, 1, 15)
        addShipLine([CGPoint(x: 253, y: 204), CGPoint(x: 30, y: 143)], shadow, 1, 15)
        addShipLine([CGPoint(x: -247, y: 192), CGPoint(x: 253, y: 184)], SKColor(white: 0.25, alpha: 0.7), 0.8, 15)
        addShipLine([CGPoint(x: -250, y: 218), CGPoint(x: -240, y: 218)], SKColor(red: 0.8, green: 0.16, blue: 0.12, alpha: 1), 3, 17)

        // Bow rail, stern fittings, anchor detail, and ship name.
        addShipLine([CGPoint(x: 267, y: 81), CGPoint(x: 301, y: 57), CGPoint(x: 307, y: 39)], shadow, 1.5, 16)
        addShipLine([CGPoint(x: -278, y: 69), CGPoint(x: -300, y: 60), CGPoint(x: -304, y: 47)], shadow, 1.5, 16)
        addShipRect(12, 5, 292, 28, SKColor(white: 0.50, alpha: 1), shadow, 1, 9)
        let name = SKLabelNode(fontNamed: "Georgia-Bold")
        name.text = "FLOATLAB"
        name.fontSize = 10
        name.fontColor = SKColor(red: 0.88, green: 0.84, blue: 0.70, alpha: 1)
        name.position = CGPoint(x: 0, y: 17)
        name.zPosition = 15
        shipArt.addChild(name)

        // Small reflections and a thin foam line make the waterline legible.
        addShipLine([CGPoint(x: -300, y: 35), CGPoint(x: -210, y: 26), CGPoint(x: -100, y: 20),
                     CGPoint(x: 40, y: 19), CGPoint(x: 180, y: 25), CGPoint(x: 300, y: 42)],
                    SKColor(red: 0.92, green: 0.94, blue: 0.88, alpha: 0.9), 1.2, 18)
    }

    private enum Material: Equatable { case steel, deck }
    private func addParticle(_ p: CGPoint, mass: CGFloat, radius: CGFloat, kind: Material) {
        let node = SKShapeNode(circleOfRadius: radius)
        node.fillColor = kind == .steel ? SKColor(red: 0.64, green: 0.16, blue: 0.12, alpha: 1) : SKColor(white: 0.72, alpha: 1)
        node.strokeColor = SKColor(white: 0.95, alpha: 0.65); node.lineWidth = 1
        node.position = p; node.zPosition = 4; node.alpha = 0.01; addChild(node)
        particles.append(HullParticle(position: p, previous: p, mass: mass, radius: radius, node: node, material: kind))
    }
    private func connect(_ a: Int, _ b: Int, stiffness: CGFloat) {
        guard a < particles.count, b < particles.count else { return }
        let line = SKShapeNode()
        line.strokeColor = SKColor(red: 0.76, green: 0.27, blue: 0.19, alpha: 1)
        line.lineWidth = 1.1; line.alpha = 0.18; line.zPosition = 2; addChild(line)
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
            var acceleration = CGVector(dx: 0, dy: -440 - waterMass * 0.42)
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
        // Break overstressed structural members. The freed nodes remain in the simulation
        // and therefore behave as independently buoyant hull fragments.
        var brokenNow = 0
        springs.removeAll { spring in
            let stretch = distance(particles[spring.a].position, particles[spring.b].position)
            if stretch > spring.rest * (1.48 - spring.stiffness * 0.18) {
                spring.node.removeFromParent()
                brokenNow += 1
                return true
            }
            return false
        }
        if brokenNow > 0 {
            leakCount += brokenNow
            flood = min(100, flood + Double(brokenNow) * 2.5)
            waterMass += CGFloat(brokenNow) * 1.8
        }
        let hullPath = CGMutablePath()
        if particles.count >= 4 {
            hullPath.move(to: particles[0].position)
            for i in stride(from: 2, to: particles.count, by: 2) { hullPath.addLine(to: particles[i].position) }
            for i in stride(from: particles.count - 1, through: 1, by: -2) { hullPath.addLine(to: particles[i].position) }
            hullPath.closeSubpath()
        }
        hullSkin.path = hullPath
        let redPath = CGMutablePath()
        if particles.count >= 4 {
            let firstX = particles[0].position.x
            let lastX = particles[particles.count - 2].position.x
            redPath.move(to: CGPoint(x: firstX, y: waterY))
            for i in stride(from: 0, to: particles.count, by: 2) {
                redPath.addLine(to: particles[i].position)
            }
            redPath.addLine(to: CGPoint(x: lastX, y: waterY))
            redPath.closeSubpath()
        }
        hullRedBand.path = redPath

        // Keep the deck artwork aligned with the moving hull while allowing
        // the particle hull itself to flex and tear independently.
        if particles.count >= 4 {
            let leftEnd = particles[0].position
            let rightEnd = particles[particles.count - 2].position
            let midpointX = (leftEnd.x + rightEnd.x) * 0.5
            let midpointY = (leftEnd.y + rightEnd.y) * 0.5
            shipArt.position = CGPoint(x: midpointX, y: waterY - 35 + (midpointY - (waterY - 14)))
            shipArt.zRotation = atan2(rightEnd.y - leftEnd.y, rightEnd.x - leftEnd.x)
        }

        let waterHeight = min(0.72, CGFloat(flood) / 100.0 * 0.72)
        let innerPath = CGMutablePath()
        let left = particles.first?.position.x ?? 0
        let right = particles.dropFirst(2).last?.position.x ?? size.width
        let bottom = waterY - 14
        let top = waterY - 14 + waterHeight * 42
        innerPath.move(to: CGPoint(x: left + 20, y: bottom))
        innerPath.addLine(to: CGPoint(x: right - 20, y: bottom))
        innerPath.addLine(to: CGPoint(x: right - 35, y: top))
        innerPath.addLine(to: CGPoint(x: left + 35, y: top))
        innerPath.closeSubpath()
        internalWater.path = innerPath
        internalWater.isHidden = flood < 1
        for light in cabinLights {
            light.fillColor = electricalPower && flood < 35
                ? SKColor(red: 0.28, green: 0.86, blue: 1, alpha: 1)
                : SKColor(white: 0.16, alpha: 1)
        }
        if flood >= 35 { electricalPower = false }
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
            let yBase = waterY - CGFloat(i) * 13
            path.move(to: CGPoint(x: 0, y: yBase))
            for x in stride(from: CGFloat(0), through: size.width, by: 24) {
                let y = yBase + sin(x * 0.009 + time * 1.25) * (1.6 + waveEnergy * 8)
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
                let pa = particles[s.a].position
                let pb = particles[s.b].position
                let midpoint = CGPoint(x: (pa.x + pb.x) * 0.5, y: (pa.y + pb.y) * 0.5)
                if distance(midpoint, point) < 24 { s.node.removeFromParent(); return true }
                return false
            }
            let removed = before - springs.count
            leakCount += removed
            if removed > 0 { flood = min(100, flood + Double(removed) * 3) }
        case "Repair":
            // Reconnect nearby separated nodes with a fresh structural link.
            let nearby = particles.indices.filter { distance(particles[$0].position, point) < 55 }
            if nearby.count >= 2 {
                let a = nearby[0], b = nearby[nearby.count - 1]
                if a != b { connect(a, b, stiffness: 0.72); leakCount = max(0, leakCount - 1) }
            }
        case "Flood":
            flood = min(100, flood + 18)
            waterMass += 18
            if flood >= 35 { electricalPower = false }
        case "Pump":
            flood = max(0, flood - 18)
            waterMass = max(0, waterMass - 18)
            if flood < 35 { electricalPower = true }
        case "Fire": heat = min(100, heat + 28)
        case "Extinguish": heat = max(0, heat - 45)
        default: break
        }
        let ring = SKShapeNode(circleOfRadius: 24)
        ring.strokeColor = SKColor(red: 0.0, green: 0.85, blue: 1.0, alpha: 0.8); ring.lineWidth = 2
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
private func + (lhs: CGVector, rhs: CGVector) -> CGVector { CGVector(dx: lhs.dx + rhs.dx, dy: lhs.dy + rhs.dy) }
private func * (lhs: CGPoint, rhs: CGFloat) -> CGVector { CGVector(dx: lhs.x * rhs, dy: lhs.y * rhs) }
