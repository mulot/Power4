//
//  ContentView.swift
//  Power4
//
//  Created by Julien Mulot on 27/08/2024.
//

import SwiftUI
import SwiftData

let defaultSizeX = 7
let defaultSizeY = 6
let defaultBoxSpacing: CGFloat = 10
let yellowTurn: Bool = true
let redTurn: Bool = false
var turn: Bool = yellowTurn

enum CaseColor: Int {
    case blank = 0, yellow, red
}

func blankGrid(sizeX: Int, sizeY: Int) -> [[CaseColor]] {
    return [[CaseColor]].init(repeating: [CaseColor].init(repeating: CaseColor.blank, count: sizeX), count: sizeY)
}

func computeGrid(grid: [[CaseColor]], x: Int, y: Int, turn: Bool) -> [[CaseColor]] {
    let sizeY = defaultSizeY
    var newGrid = grid
    
        for i in (0...sizeY-1) {
            if (grid[(sizeY-1)-i][x] == CaseColor.blank) {
                if (turn == yellowTurn) {
                    newGrid[(sizeY-1)-i][x] = CaseColor.yellow
                }
                else {
                    newGrid[(sizeY-1)-i][x] = CaseColor.red
                }
                break
            }
        }
    return newGrid
}

struct ContentView: View {
    
    var body: some View {
            GridView()
    }
}

struct GridView: View {
    var sizeX = defaultSizeX
    var sizeY = defaultSizeY
    @State private var pt: CGPoint = .zero
    @State var grid = blankGrid(sizeX: defaultSizeX, sizeY: defaultSizeY)
    
    var body: some View {
        GeometryReader { geometry in
            let boxSpacing:CGFloat = min(geometry.size.height / CGFloat(sizeY), geometry.size.width / CGFloat(sizeX))
            let numberOfHorizontalGridLines = sizeY
            let numberOfVerticalGridLines = sizeX
            let height = CGFloat(numberOfHorizontalGridLines) * boxSpacing
            let width = CGFloat(numberOfVerticalGridLines) * boxSpacing
            let myGesture = DragGesture(minimumDistance: 0, coordinateSpace: .local).onEnded({
                self.pt = $0.startLocation
                print("Tapped at: \(pt.x), \(pt.y) Box X: \(Int(pt.x/boxSpacing)) Box Y: \(Int(pt.y/boxSpacing))")
                /*
                if (turn == yellowTurn) {
                    grid[Int(pt.y/boxSpacing)][Int(pt.x/boxSpacing)] = CaseColor.yellow
                }
                else
                {
                    grid[Int(pt.y/boxSpacing)][Int(pt.x/boxSpacing)] = CaseColor.red
                }
                */
                grid = computeGrid(grid: grid, x: Int(pt.x/boxSpacing), y: Int(pt.y/boxSpacing), turn: turn)
                turn = !turn
                /*
                 if (grid[Int(pt.y/boxSpacing)][Int(pt.x/boxSpacing)] == 0) {
                 grid[Int(pt.y/boxSpacing)][Int(pt.x/boxSpacing)] = 1
                 }
                 else {
                 grid[Int(pt.y/boxSpacing)][Int(pt.x/boxSpacing)] = 0
                 }
                 */
                //print("new box val: \(grid[Int(pt.y/boxSpacing)][Int(pt.x/boxSpacing)])")
            })
            Path { path in
                for y in (0...sizeY-1) {
                    for x in (0...sizeX-1) {
                        if (grid[y][x] == CaseColor.blank) {
                            let hOffset: CGFloat = CGFloat(x) * boxSpacing
                            let vOffset: CGFloat = CGFloat(y) * boxSpacing
                            path.move(to: CGPoint(x: 0 + hOffset, y: 0 + vOffset))
                            path.addLine(to: CGPoint(x: boxSpacing + hOffset, y: 0 + vOffset))
                            path.addLine(to: CGPoint(x: boxSpacing + hOffset, y: boxSpacing + vOffset))
                            path.addLine(to: CGPoint(x: 0 + hOffset, y: boxSpacing + vOffset))
                        }
                    }
                }
            }
            .fill(.white)
            .gesture(myGesture)
            Path { path in
                for y in (0...sizeY-1) {
                    for x in (0...sizeX-1) {
                        if (grid[y][x] == CaseColor.yellow) {
                            let hOffset: CGFloat = CGFloat(x) * boxSpacing
                            let vOffset: CGFloat = CGFloat(y) * boxSpacing
                            path.move(to: CGPoint(x: 0 + hOffset, y: 0 + vOffset))
                            path.addLine(to: CGPoint(x: boxSpacing + hOffset, y: 0 + vOffset))
                            path.addLine(to: CGPoint(x: boxSpacing + hOffset, y: boxSpacing + vOffset))
                            path.addLine(to: CGPoint(x: 0 + hOffset, y: boxSpacing + vOffset))
                        }
                    }
                }
            }
            .fill(.yellow)
            .gesture(myGesture)
            Path { path in
                for y in (0...sizeY-1) {
                    for x in (0...sizeX-1) {
                        if (grid[y][x] == CaseColor.red) {
                            let hOffset: CGFloat = CGFloat(x) * boxSpacing
                            let vOffset: CGFloat = CGFloat(y) * boxSpacing
                            path.move(to: CGPoint(x: 0 + hOffset, y: 0 + vOffset))
                            path.addLine(to: CGPoint(x: boxSpacing + hOffset, y: 0 + vOffset))
                            path.addLine(to: CGPoint(x: boxSpacing + hOffset, y: boxSpacing + vOffset))
                            path.addLine(to: CGPoint(x: 0 + hOffset, y: boxSpacing + vOffset))
                        }
                    }
                }
            }
            .fill(.red)
            .gesture(myGesture)
            Path { path in
                for index in 0...numberOfVerticalGridLines {
                    let vOffset: CGFloat = CGFloat(index) * boxSpacing
                    path.move(to: CGPoint(x: vOffset, y: 0))
                    path.addLine(to: CGPoint(x: vOffset, y: height))
                }
                for index in 0...numberOfHorizontalGridLines {
                    let hOffset: CGFloat = CGFloat(index) * boxSpacing
                    path.move(to: CGPoint(x: 0, y: hOffset))
                    path.addLine(to: CGPoint(x: width, y: hOffset))
                }
            }
            .stroke(Color.black)
            //.background(Color.blue)
            /*
             .onAppear()
             {
             print("geo height: \(geometry.size.height) geo width: \(geometry.size.width) boxSpacing: \(boxSpacing) #H lines: \(numberOfHorizontalGridLines) #V lines: \(numberOfVerticalGridLines) height: \(height) width: \(width)")
             }
             */
        }
    }
}

#Preview {
    ContentView()
}
