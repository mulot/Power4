//
//  ContentView.swift
//  Power4
//
//  Created by Julien Mulot on 27/08/2024.
//

import SwiftUI
import SwiftData
import CoreML

let defaultSizeX = 7
let defaultSizeY = 6
let defaultBoxSpacing: CGFloat = 10
/// Number of aligned tokens of the same color to win the game
let defaultVictory: Int = 4
let yellowTurn: Bool = true
let redTurn: Bool = false
/// Color of the player of the current move
var turn: Bool = yellowTurn
var nbVictoryYellow: Int = 0
var nbVictoryRed: Int = 0
var partyLock: Bool = false
let redIA: Bool = true
let yellowIA: Bool = false


/// Values for colors of the grid
enum CaseColor: Int {
    case blank = 0, yellow, red
}


/// export game results to CSV file
/// - Parameters:
///   - grid: end of game grid
///   - victory: victory color
func exportResult(grid: [[CaseColor]], victory: CaseColor) {
    let BUFFER_LINES:Int = 200000000
    //let timestamp = Date().timeIntervalSince1970
    //let filePath = "/Users/mulot/Downloads/power4-result-\(timestamp).csv"
    let filePath = "/Users/mulot/Downloads/power4-result.csv"
    if FileManager.default.fileExists(atPath: filePath) == false {
        FileManager.default.createFile(atPath: filePath, contents: nil, attributes: nil)
    }
    let cvsFile = FileHandle(forWritingAtPath: filePath)
    if (cvsFile != nil) {
        //print("IS file!")
        print(filePath)
        do {
            try cvsFile!.seekToEnd()
        }
        catch {
            print("Error seeking to end of file")
        }
        var cvsData = Data(capacity: BUFFER_LINES)
        var cvsStr: String
        //cvsStr = "1;2;3;4;5.6:7"
        cvsStr = String()
        for y in (0...defaultSizeY-1) {
            for x in (0...defaultSizeX-1) {
                if (grid[y][x] == CaseColor.red) {
                    cvsStr += "1,"
                }
                else if (grid[y][x] == CaseColor.yellow) {
                    cvsStr += "2,"
                }
                else
                {
                    cvsStr += "0,"
                }
                //cvsStr += "X\(x)Y\(y),"
                
            }
        }
        if (victory == CaseColor.yellow) {
            cvsStr += "2\n"
        }
        else {
            cvsStr += "1\n"
        }
        cvsData.append(cvsStr.data(using: String.Encoding.ascii)!)
        cvsFile!.write(cvsData)
        cvsFile!.synchronizeFile()
        cvsFile!.closeFile()
    }
    else {
        //print("NO file !")
    }
}


/// Return a blank new grid
/// - Parameters:
///   - sizeX: X size of the new grid
///   - sizeY: Y size of the new grid
/// - Returns: blank grid
func blankGrid(sizeX: Int, sizeY: Int) -> [[CaseColor]] {
    return [[CaseColor]].init(repeating: [CaseColor].init(repeating: CaseColor.blank, count: sizeX), count: sizeY)
}


/// Check if color is a winner for the current grid
/// - Parameters:
///   - grid: current grid
///   - color: color to check
/// - Returns: is winner or not
func checkVictory(grid: [[CaseColor]], color: CaseColor) -> Bool {
    for y in (0...defaultSizeY-1) {
        for x in (0...defaultSizeX-1) {
            if (grid[y][x] == color) {
                if ((x + defaultVictory - 1) <= defaultSizeX-1) {
                    var nb = 0
                    for i in (0...(defaultVictory-1)) {
                        if (grid[y][x+i] != color) {
                            break
                        }
                        nb += 1
                    }
                    if (nb == defaultVictory) {
                        return true
                    }
                }
                if ((y + defaultVictory - 1) <= defaultSizeY-1) {
                    var nb = 0
                    for i in (0...(defaultVictory-1)) {
                        if (grid[y+i][x] != color) {
                            break
                        }
                        nb += 1
                    }
                    if (nb == defaultVictory) {
                        return true
                    }
                }
                if (((y + defaultVictory - 1) <= defaultSizeY-1) && ((x + defaultVictory - 1) <= defaultSizeX-1)) {
                    var nb = 0
                    for i in (0...(defaultVictory-1)) {
                        if (grid[y+i][x+i] != color) {
                            break
                        }
                        nb += 1
                    }
                    if (nb == defaultVictory) {
                        return true
                    }
                }
                if (((y + defaultVictory - 1) <= defaultSizeY-1) && ((x - (defaultVictory - 1)) >= 0)) {
                    var nb = 0
                    for i in (0...(defaultVictory-1)) {
                        if (grid[y+i][x-i] != color) {
                            break
                        }
                        nb += 1
                    }
                    if (nb == defaultVictory) {
                        return true
                    }
                }
            }
        }
    }
    //print ("Victory: \(isVictory)")
    return false
}


/// Play the color where the current player has clicked
/// - Parameters:
///   - grid: current grid
///   - x: X position of click
///   - y: Y position of click
/// - Returns: new grid with the played color of the player
func computeGrid(grid: [[CaseColor]], x: Int, y: Int) -> [[CaseColor]]  {
    let sizeY = defaultSizeY
    var newGrid = grid
    
    if (!partyLock) {
        for i in (0...sizeY-1) {
            if (grid[(sizeY-1)-i][x] == CaseColor.blank) {
                if (turn == yellowTurn) {
                    newGrid[(sizeY-1)-i][x] = CaseColor.yellow
                    //turn = !turn
                    return newGrid
                    
                }
                else {
                    newGrid[(sizeY-1)-i][x] = CaseColor.red
                    //turn = !turn
                    return newGrid
                }
            }
        }
    }
    return newGrid
}


/// Check if the next move of the player enemy could win and play the move it if it could win
/// - Parameters:
///   - grid: current grid
///   - color: player color
/// - Returns: new grid if the enemy move is countered, nil if not
func checkEnemyNextMove(grid: [[CaseColor]], color: CaseColor) -> [[CaseColor]]? {
    var newGrid = grid
    var tmpGrid: [[CaseColor]]
    var enemyColor: CaseColor = CaseColor.red
    
    if (color == CaseColor.red) {
        enemyColor = CaseColor.yellow
    }
    
    for x in (0...defaultSizeX-1) {
        for y in (0...defaultSizeY-1) {
            if (grid[(defaultSizeY-1)-y][x] == CaseColor.blank) {
                tmpGrid = grid
                tmpGrid[(defaultSizeY-1)-y][x] = enemyColor
                if (checkVictory(grid: tmpGrid, color: enemyColor)) {
                    print("counter enemy who will win in y: \((defaultSizeY-1)-y) x: \(x)")
                    tmpGrid[(defaultSizeY-1)-y][x] = color
                    newGrid = tmpGrid
                    //turn = !turn
                    return newGrid
                }
                break
            }
        }
    }
    return nil
}


/// Convert a grid with colors to the corresponding grid with integer values
/// - Parameter grid: current grid with color values
/// - Returns: a grid of integer values for each color value
func convertGridToML(grid: [[CaseColor]]) -> [[Int64]] {
    var result: [[Int64]]
    
    let sizeY = grid.count
    let sizeX = grid[0].count
    result = Array(repeating: Array(repeating: 0, count: sizeX), count: sizeY)
    
    for y in (0...defaultSizeY-1) {
        for x in (0...defaultSizeX-1) {
            switch grid[y][x] {
            case .red:
                result[y][x] = 1
            case .yellow:
                result[y][x] = 2
            case .blank:
                result[y][x] = 0
            }
        }
    }
    return result
}


/// Play the next move with an IA based on a Machine Learning model
/// - Parameters:
///   - grid: current grid
///   - color: color of the IA
/// - Returns: New grid played by the ML model
func playML(grid: [[CaseColor]], color: CaseColor) -> [[CaseColor]]?  {
    var newGrid: [[CaseColor]]?
    var tmpGrid: [[CaseColor]]
    var gridML: [[Int64]]
    var bestPrediction: Double = 0.0
   
    //check if there is a winning move for the color
    for x in (0...defaultSizeX-1) {
        for y in (0...defaultSizeY-1) {
            if (grid[(defaultSizeY-1)-y][x] == CaseColor.blank) {
                tmpGrid = grid
                tmpGrid[(defaultSizeY-1)-y][x] = color
                if (checkVictory(grid: tmpGrid, color: color)) {
                    newGrid = tmpGrid
                    //turn = !turn
                    return newGrid
                }
                break
            }
        }
    }
    
    //check if there is a winning move for the enemy and take it
    let result = checkEnemyNextMove(grid: grid, color: color)
    if (result != nil)
    {
        return result!
    }
    
    //ML play
    do {
        let config = MLModelConfiguration()
        let model = try Power4ML(configuration: config)
        for x in (0...defaultSizeX-1) {
            for y in (0...defaultSizeY-1) {
                if (grid[(defaultSizeY-1)-y][x] == CaseColor.blank) {
                    tmpGrid = grid
                    tmpGrid[(defaultSizeY-1)-y][x] = color
                    do {
                        gridML = convertGridToML(grid: tmpGrid)
                        let prediction = try model.prediction(X0Y0: gridML[0][0], X1Y0: gridML[0][1], X2Y0: gridML[0][2], X3Y0: gridML[0][3], X4Y0: gridML[0][4], X5Y0: gridML[0][5], X6Y0: gridML[0][6], X0Y1: gridML[1][0], X1Y1: gridML[1][1], X2Y1: gridML[1][2], X3Y1: gridML[1][3], X4Y1: gridML[1][4], X5Y1: gridML[1][5], X6Y1: gridML[1][6], X0Y2: gridML[2][0], X1Y2: gridML[2][1], X2Y2: gridML[2][2], X3Y2: gridML[2][3], X4Y2: gridML[2][4], X5Y2: gridML[2][5], X6Y2: gridML[2][6], X0Y3: gridML[3][0], X1Y3: gridML[3][1], X2Y3: gridML[3][2], X3Y3: gridML[3][3], X4Y3: gridML[3][4], X5Y3: gridML[3][5], X6Y3: gridML[3][6], X0Y4: gridML[4][0], X1Y4: gridML[4][1], X2Y4: gridML[4][2], X3Y4: gridML[4][3], X4Y4: gridML[4][4], X5Y4: gridML[4][5], X6Y4: gridML[4][6], X0Y5: gridML[5][0], X1Y5: gridML[5][1], X2Y5: gridML[5][2], X3Y5: gridML[5][3], X4Y5: gridML[5][4], X5Y5: gridML[5][5], X6Y5: gridML[5][6])
                        print("Prediction: \(prediction.Winner) in X: \(x) Y: \(y)")
                        if (color == CaseColor.red) {
                            if ((2 - prediction.Winner) < (2 - bestPrediction)) {
                                print("Red best prediction: \(prediction.Winner) in X: \(x) Y: \(y)")
                                bestPrediction = prediction.Winner
                                newGrid = tmpGrid
                            }
                        }
                        else if (color == CaseColor.yellow) {
                            if ((1 - prediction.Winner) > (1 - bestPrediction)) {
                                print("Yellow best prediction: \(prediction.Winner) in X: \(x) Y: \(y)")
                                bestPrediction = prediction.Winner
                                newGrid = tmpGrid
                            }
                        }
                    } catch {
                        print("ML failed")
                    }
                    break
                }
            }
        }
    } catch {
        
    }
    //turn = !turn
    //print(newGrid)
    return newGrid
}


/// Play the next move with an IA based on conditions
/// - Parameters:
///   - grid: current grid
///   - color: color of the IA
/// - Returns: New grid played by the IA
func playIA(grid: [[CaseColor]], color: CaseColor) -> [[CaseColor]]?  {
    var newGrid: [[CaseColor]]?
    var tmpGrid: [[CaseColor]]
    var xList = [Int](0...(defaultSizeX-1))
    /*
     var enemyColor: CaseColor = CaseColor.red
     
     if (color == CaseColor.red) {
     enemyColor = CaseColor.yellow
     }
     */
    
    //check if there is a winning move for the color
    for x in (0...defaultSizeX-1) {
        for y in (0...defaultSizeY-1) {
            if (grid[(defaultSizeY-1)-y][x] == CaseColor.blank) {
                tmpGrid = grid
                tmpGrid[(defaultSizeY-1)-y][x] = color
                if (checkVictory(grid: tmpGrid, color: color)) {
                    newGrid = tmpGrid
                    //turn = !turn
                    return newGrid
                }
                break
            }
        }
    }
    
    //check if there is a winning move for the enemy next move
    /*
     for x in (0...defaultSizeX-1) {
     for y in (0...defaultSizeY-1) {
     if (grid[(defaultSizeY-1)-y][x] == CaseColor.blank) {
     tmpGrid = grid
     tmpGrid[(defaultSizeY-1)-y][x] = enemyColor
     if (checkVictory(grid: tmpGrid, color: enemyColor)) {
     print("counter enemy who will win in y: \((defaultSizeY-1)-y) x: \(x)")
     tmpGrid[(defaultSizeY-1)-y][x] = color
     newGrid = tmpGrid
     turn = !turn
     return newGrid
     }
     break
     }
     }
     }
     */
    let result = checkEnemyNextMove(grid: grid, color: color)
    if (result != nil)
    {
        return result!
    }
    
    //random play
    while (!xList.isEmpty)
    {
        let r = Int.random(in: 0...(xList.count-1))
        //print("r :\(r) List elt: \(xList[r])")
        for y in (0...defaultSizeY-1) {
            if (grid[(defaultSizeY-1)-y][r] == CaseColor.blank) {
                tmpGrid = grid
                tmpGrid[(defaultSizeY-1)-y][r] = color
                let result = checkEnemyNextMove(grid: tmpGrid, color: color)
                /*
                 if (checkVictory(grid: tmpGrid, color: enemyColor)) {
                 print("counter 2nd enemy move who will win in y: \((defaultSizeY-1)-y) x: \(r)")
                 break
                 }
                 */
                if (result != nil)
                {
                    print("counter 2nd enemy move who will win in y: \((defaultSizeY-1)-y) x: \(r)")
                    break
                }
                else {
                    print("play random in y: \((defaultSizeY-1)-y) x: \(r)")
                    newGrid = grid
                    newGrid![(defaultSizeY-1)-y][r] = color
                    //turn = !turn
                    return newGrid
                }
            }
        }
        xList.remove(at: r)
    }
    return newGrid
}

struct ContentView: View {
    
    var body: some View {
            Power4View()
    }
}

struct GridView: View {
    var sizeX = defaultSizeX
    var sizeY = defaultSizeY
    var lineColor = Color.black
    
    var body: some View {
        GeometryReader { geometry in
            let boxSpacing:CGFloat = min(geometry.size.height / CGFloat(sizeY), geometry.size.width / CGFloat(sizeX))
            let numberOfHorizontalGridLines = sizeY
            let numberOfVerticalGridLines = sizeX
            let height = CGFloat(numberOfHorizontalGridLines) * boxSpacing
            let width = CGFloat(numberOfVerticalGridLines) * boxSpacing
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
            .stroke(lineColor)
        }
    }
}

struct Power4View: View {
    var sizeX = defaultSizeX
    var sizeY = defaultSizeY
    @State private var pt: CGPoint = .zero
    @State var grid = blankGrid(sizeX: defaultSizeX, sizeY: defaultSizeY)
    @State var victoryText = ""
    @State var victoryColor = Color.black
    
    func checkTurn()
    {
        if (!partyLock) {
            if (checkVictory(grid: grid, color: CaseColor.yellow))
            {
                print ("Yellow Victory")
                victoryText = "Yellow Victory !!!!!"
                victoryColor = .yellow
                nbVictoryYellow += 1
                exportResult(grid: grid, victory: CaseColor.yellow)
                partyLock = true
            }
            else if (checkVictory(grid: grid, color: CaseColor.red))
            {
                print ("Red Victory")
                victoryText = "Red Victory !!!!!"
                victoryColor = .red
                nbVictoryRed += 1
                exportResult(grid: grid, victory: CaseColor.red)
                partyLock = true
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let boxSpacing:CGFloat = min(geometry.size.height / CGFloat(sizeY), geometry.size.width / CGFloat(sizeX))
            let myGesture = DragGesture(minimumDistance: 0, coordinateSpace: .local).onEnded({
                self.pt = $0.startLocation
                //print("Tapped at: \(pt.x), \(pt.y) Box X: \(Int(pt.x/boxSpacing)) Box Y: \(Int(pt.y/boxSpacing))")
                grid = computeGrid(grid: grid, x: Int(pt.x/boxSpacing), y: Int(pt.y/boxSpacing))
                turn = !turn
                checkTurn()
                if (turn == redTurn && redIA && !partyLock) {
                    //print("IA red turn\n")
                    //grid = playIA(grid: grid, color: CaseColor.red)
                    grid = playML(grid: grid, color: CaseColor.red) ?? playIA(grid: grid, color: CaseColor.red)!
                    turn = !turn
                }
                checkTurn()
            })
            //draw game board
            Path { path in
                for y in (0...sizeY-1) {
                    for x in (0...sizeX-1) {
                            let hOffset: CGFloat = CGFloat(x) * boxSpacing
                            let vOffset: CGFloat = CGFloat(y) * boxSpacing
                            path.move(to: CGPoint(x: 0 + hOffset, y: 0 + vOffset))
                            path.addLine(to: CGPoint(x: boxSpacing + hOffset, y: 0 + vOffset))
                            path.addLine(to: CGPoint(x: boxSpacing + hOffset, y: boxSpacing + vOffset))
                            path.addLine(to: CGPoint(x: 0 + hOffset, y: boxSpacing + vOffset))
                    }
                }
            }
            .fill(.blue)
            .gesture(myGesture)
            //draw game board circle
            Path { path in
                for y in (0...sizeY-1) {
                    for x in (0...sizeX-1) {
                        if (grid[y][x] == CaseColor.blank) {
                            let hOffset: CGFloat = CGFloat(x) * boxSpacing
                            let vOffset: CGFloat = CGFloat(y) * boxSpacing
                            path.addArc(center: CGPoint(x: hOffset + (boxSpacing / 2), y: vOffset + (boxSpacing / 2)), radius: boxSpacing / 2, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: true)
                        }
                    }
                }
            }
            .fill(.white)
            .gesture(myGesture)
            //draw yellow pieces
            Path { path in
                for y in (0...sizeY-1) {
                    for x in (0...sizeX-1) {
                        if (grid[y][x] == CaseColor.yellow) {
                            let hOffset: CGFloat = CGFloat(x) * boxSpacing
                            let vOffset: CGFloat = CGFloat(y) * boxSpacing
                            path.addArc(center: CGPoint(x: hOffset + (boxSpacing / 2), y: vOffset + (boxSpacing / 2)), radius: boxSpacing / 2, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: true)
                        }
                    }
                }
            }
            .fill(.yellow)
            .gesture(myGesture)
            //draw red pieces
            Path { path in
                for y in (0...sizeY-1) {
                    for x in (0...sizeX-1) {
                        if (grid[y][x] == CaseColor.red) {
                            let hOffset: CGFloat = CGFloat(x) * boxSpacing
                            let vOffset: CGFloat = CGFloat(y) * boxSpacing
                            path.addArc(center: CGPoint(x: hOffset + (boxSpacing / 2), y: vOffset + (boxSpacing / 2)), radius: boxSpacing / 2, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: true)
                        }
                    }
                }
            }
            .fill(.red)
            .gesture(myGesture)
            GridView()
        }
        HStack {
            Text("Yellow: \(nbVictoryYellow)")
                .foregroundStyle(Color.yellow)
            Text("Red \(nbVictoryRed)")
                .foregroundStyle(Color.red)
            Spacer()
            Button( action: {
                grid = blankGrid(sizeX: defaultSizeX, sizeY: defaultSizeY)
                victoryText = ""
                victoryColor = .black
                turn = yellowTurn
                partyLock = false
            }) {
                Label("Reset", systemImage: "restart")
            }
            Text(victoryText)
                .foregroundStyle(victoryColor)
            Spacer()
            Label("Turn", systemImage: "circle.fill")
                .foregroundColor(turn == yellowTurn ? Color.yellow : Color.red)
        }
    }
}

#Preview {
    ContentView()
}
