//
//  GameView.swift
//  Block Drop
//
//  Created by Jack Elia on 8/7/22.
//

import SwiftUI

struct GameView: View {
    
    @State var score = 0
    @State var gridTiles: [[GridTile]]
    @State var blocks = [Block]()
    @StateObject var block1 = Block(shape: [[1, 0, 0], [0, 0, 0], [0, 0, 0]], image: Image("block-example"))
    @StateObject var block2 = Block(shape: [[1, 0, 0], [1, 0, 0], [1, 0, 0]], image: Image("block-example"))
    @StateObject var block3 = Block(shape: [], image: Image("block-example"))
    
    let gridWidth = 9
    let gridHeight = 9
    let maxBlocks = 3
    
    init() {
        gridTiles = [[GridTile]](repeating: [GridTile](repeating: GridTile(tileNumber: 0, tileFrame: .zero), count: gridHeight), count: gridWidth)
    }

    var body: some View {
        VStack(spacing: 0) {
            drawScoreView()
            drawGrid()
            makeBlockHolding()
        }
        .onAppear {
            // Creates the 3 game blocks
            blocks = [block1, block2, block3]
        }
    }
    
    // MARK: The Score View
    /// Draws the score view each time it needs to be updated
    @ViewBuilder func drawScoreView() -> some View {
        HStack {
            Text("Title Goes Here")
            Spacer()
            Text("Score: \(score)")
        }
        .padding(20)
        .background(.purple)
    }
    
    // MARK: The Grid View
    /// Draws the grid each time it needs to be updated
    @ViewBuilder func drawGrid() -> some View {
        VStack(spacing: 0) {
            ForEach(0..<gridTiles.count, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<gridTiles[row].count, id: \.self) { col in
                        getCellImage(tileNumber: gridTiles[row][col].tileNumber)
                            .resizable()
                            .scaledToFit()
                            .overlay(GeometryReader { geometry in
                                getCellOverlayColor(row, col)
                                    .opacity(0.6)
                                    .onAppear {
                                        // Sets the value of the actual cell, not the copy of it
                                        gridTiles[row][col].tileFrame = geometry.frame(in: .global)
                                    }
                            }
                        )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(10)
        .background(.blue)
    }
    
    func getCellImage(tileNumber: Int) -> Image {
        switch tileNumber {
        case 0:
            return Image("redsquare")
        case 1:
            return Image("greensquare")
        default:
            // This should not be called
            return Image("")
        }
    }
    
    func getCellOverlayColor(_ row: Int, _ col: Int) -> Color {
        var overlayColor = Color.clear
        if gridTiles[row][col].isBeingHovered {
            overlayColor = .white
            for block in blocks {
                // Makes the hover effect red if it cannot be placed
                if !block.fitsOnGrid && block.isPickedUp {
                    overlayColor = .red
                }
            }
        } else if gridTiles[row][col].tileNumber == 0 {
            // Makes the sub sections of the grid different colors
            if Int(floor(Double(col / 3)) + 3 * floor(Double(row) / 3.0)) % 2 == 0 {
                overlayColor = .green
            }
        }
        return overlayColor
    }
    
    // MARK: The Block Hold View
    /// Makes the block holding area
    @ViewBuilder func makeBlockHolding() -> some View {
        HStack {
            // Makes the block images
            ForEach(0..<blocks.count, id: \.self) { i in
                let block = blocks[i]
                VStack(spacing: 0) {
                    ForEach(0..<block.shape.count, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<block.shape[row].count, id: \.self) { col in
                                // Draws each of the blocks from their shape
                                if block.shape[row][col] == 1{
                                    Image("greensquare")
                                        .resizable()
                                        .scaledToFit()
                                        .opacity(1)
                                } else {
                                    Image("redsquare")
                                        .resizable()
                                        .scaledToFit()
                                        .opacity(0)
                                }
                            }
                        }
                    }
                }
                .frame(width: 96, height: 96, alignment: .center)
                // Moves the block while it is being dragged
                .offset(block.offset)
                // Handles the logic behind block dragging and dropping
                .gesture(
                    DragGesture(minimumDistance: .zero, coordinateSpace: .global)
                        .onChanged { gesture in
                            block.offset = CGSize(width: gesture.translation.width - 40, height: gesture.translation.height - 40)
                            block.position = CGPoint(x: gesture.location.x - 60, y: gesture.location.y - 20)
                            block.isPickedUp = true
                            resetGridHover()
                            block.fitsOnGrid = checkIfBlockFitsOnGrid(block)
                        }
                        .onEnded { _ in
                            // Do stuff for dropping the block
                            block.offset = .zero
                            block.isPickedUp = false
                            if block.fitsOnGrid {
                                dropBlockOnGrid(block)
                            }
                            resetGridHover()
                        }
                    )
                if i < blocks.count - 1 { // Makes spacers after every block but the last
                    Spacer()
                }
            }
        }
        .padding(20)
        .background(.green)
    }

    func resetGridHover() {
        for row in 0..<gridTiles.count {
            for col in 0..<gridTiles[row].count {
                gridTiles[row][col].isBeingHovered = false
            }
        }
    }
    
    func checkIfBlockFitsOnGrid(_ block: Block) -> Bool {
        var blockFitsOnGrid = true
        // Loops through each tile on the grid
        for gridRow in 0..<gridTiles.count {
            for gridCol in 0..<gridTiles[gridRow].count {
                // Checks if the block is being dragged over the tile
                if gridTiles[gridRow][gridCol].tileFrame.contains(block.position) {
                    let blockShape = block.shape
                    // Loops through each tile on the block
                    for blockRow in 0..<blockShape.count {
                        for blockCol in 0..<blockShape[blockRow].count {
                            let blockTile = blockShape[blockRow][blockCol]
                            // Only does checks if there is a filled tile
                            if blockTile != 0 {
                                // Checks to make sure the block tile is within the grid
                                if gridRow + blockRow < gridTiles.count && gridCol + blockCol < gridTiles[gridRow].count {
                                    // This is the grid tile it is currently checking
                                    if gridTiles[gridRow + blockRow][gridCol + blockCol].tileNumber != 0 {
                                        // Is false because something in the grid is in the way
                                        blockFitsOnGrid = false
                                    } else {
                                        gridTiles[gridRow + blockRow][gridCol + blockCol].isBeingHovered = true
                                    }
                                } else {
                                    // Is false because block doesn't fit within grid
                                    blockFitsOnGrid = false
                                }
                                
                            }
                        }
                    }
                    return blockFitsOnGrid
                }
            }
        }
        // Returns false because the block isn't even over the grid
        return false
    }
    
    func dropBlockOnGrid(_ block: Block) {
        for row in 0..<gridTiles.count {
            for col in 0..<gridTiles[row].count {
                if gridTiles[row][col].isBeingHovered {
                    gridTiles[row][col].tileNumber = 1
                }
            }
        }
    }
    
}

struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        GameView()
    }
}
