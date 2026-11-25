import SwiftUI
import AppKit

struct Cell: View {
    let demo: Demo
    let moment: DemoMoment
    var body: some View {
        Canvas { context, size in
            DemoRenderer(demo: demo, frame: demo.bounds).draw(moment, in: &context, size: size)
        }
        .frame(width: 230, height: 230)
        .background(Palette.ink)
    }
}

struct Sheet: View {
    let ids: [ExerciseID]
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(ids, id: \.self) { id in
                let demo = Demos.of(id)
                HStack(spacing: 4) {
                    Text(id.rawValue).font(.system(size: 15, weight: .bold)).foregroundStyle(.white).frame(width: 110, alignment: .leading)
                    Cell(demo: demo, moment: DemoMoment(end: 0, progress: 0))
                    Cell(demo: demo, moment: DemoMoment(end: 0, progress: 0.5))
                    Cell(demo: demo, moment: DemoMoment(end: 0, progress: 1))
                    if demo.ends.count > 1 { Cell(demo: demo, moment: DemoMoment(end: 1, progress: 1)) }
                }
            }
        }
        .padding(6)
        .background(Color.black)
    }
}

let args = CommandLine.arguments
let out = args[1]
let only = args.count > 2 ? args[2].split(separator: ",").compactMap { ExerciseID(rawValue: String($0)) } : ExerciseID.allCases
MainActor.assumeIsolated {
    let ids = Array(only)
    for (n, start) in stride(from: 0, to: ids.count, by: 6).enumerated() {
        let chunk = Array(ids[start..<min(start + 6, ids.count)])
        let renderer = ImageRenderer(content: Sheet(ids: chunk))
        renderer.scale = 1
        guard let image = renderer.cgImage else { print("render failed"); continue }
        let rep = NSBitmapImageRep(cgImage: image)
        let data = rep.representation(using: .png, properties: [:])!
        let path = "\(out)/sheet-\(n).png"
        try! data.write(to: URL(fileURLWithPath: path))
        print(path)
    }
}
