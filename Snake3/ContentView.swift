//
//  ContentView.swift
//  Snake3
//
//  Created by David DeLuca on 11/1/26.
//

import Combine
import Observation
import SwiftUI

@MainActor
@Observable
final class GameModel {

  struct Snake {

    enum Direction {
      case left, up, down, right
    }

    var direction: Direction = .right

    struct Segment {
      let x: Int
      let y: Int
    }

    var segments: [Segment]
    var head: Segment? { segments.last }
  }

  var snake = Snake(segments: [
    Snake.Segment(x: 0, y: 0)
  ])

  struct World {
    let width: Int
    let height: Int

    init(width: Int = 32, height: Int = 32) {
      self.width = width
      self.height = height
    }
  }

  var world = World()

  func step() {

    guard let head = snake.head else {
      print("Cannot move headless snake.")
      return
    }

    let newHead: Snake.Segment =
      switch snake.direction {
      case .left: .init(x: head.x - 1, y: head.y + 0)
      case .right: .init(x: head.x + 1, y: head.y + 0)
      case .up: .init(x: head.x + 0, y: head.y - 1)
      case .down: .init(x: head.x + 0, y: head.y + 1)
      }

    print("New head is \(newHead)")

    guard isInBounds(newHead) else {
      print("New head is out of bounds")
      return
    }
    
    snake.segments.append(newHead)
        
    snake.segments.removeFirst()

    // TODO: Process food
  }

  func isInBounds(_ segment: Snake.Segment) -> Bool {
    segment.x > 0 && segment.x < world.width && segment.y > 0 && segment.y < world.height
  }
}

struct ContentView: View {

  let model: GameModel

  @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

  var body: some View {
    VStack {
      Color.black
        .frame(width: 640, height: 640)
        .overlay {
          GeometryReader { proxy in
            SnakeView(snake: model.snake, world: model.world, bounds: proxy)
          }
        }
    }
    .padding()
    .onReceive(timer) { _ in
      model.step()
    }
    // TODO: Input handling
  }
}

struct SnakeView: View {

  let snake: GameModel.Snake
  let world: GameModel.World
  let bounds: GeometryProxy

  var body: some View {
    let h = bounds.size.height
    let w = bounds.size.width
    let rows = world.height
    let cols = world.width
    let block = CGSize(width: w / CGFloat(cols), height: h / CGFloat(rows))
    Path { p in
      if let head = snake.head {
        p.move(to: CGPoint(x: head.x, y: head.y).scaled(by: block))
        p.addLine(to: CGPoint(x: head.x, y: head.y).scaled(by: block))
        for segment in snake.segments.dropLast().reversed() {
          p.addLine(to: CGPoint(x: segment.x, y: segment.y).scaled(by: block))
        }
      }
    }
    .offset(x: block.width * 0.5, y: block.height * 0.5)
    .stroke(style: StrokeStyle(lineWidth: block.longerSize, lineCap: .round, lineJoin: .round))
    .foregroundStyle(Color.green)
  }
}

extension CGPoint {
  func scaled(by size: CGSize) -> CGPoint {
    CGPoint(x: x * size.width, y: y * size.height)
  }
}

extension CGSize {
  var longerSize: CGFloat {
    max(width, height)
  }
}

#Preview {
  ContentView(
    model: {
      let model = GameModel()
      model.snake.segments = [
        .init(x: 0, y: 0),
        .init(x: 1, y: 0),
        .init(x: 1, y: 1),
      ]
      return model
    }()
  )
}
