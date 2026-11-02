//
//  ContentView.swift
//  Snake3
//
//  Created by David DeLuca on 11/1/26.
//

import Combine
import Observation
import SwiftUI

struct Location: Equatable, Hashable {
  var x: Int = 0
  var y: Int = 0
}

@MainActor
@Observable
final class GameModel {

  struct Snake {

    enum Direction {
      case left, up, down, right
    }

    var direction: Direction = .right

    struct Segment {
      var location: Location
    }

    var segments: [Segment]
    var head: Segment? { segments.last }
  }

  var snake = Snake(segments: [
    Snake.Segment(location: Location(x: 0, y: 0))
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

  struct Food: Hashable {
    var location = Location()
  }

  var food = [Food]()

  func placeFood(count: Int = 1) {
    for _ in 0..<count {
      var candidate = Food()
      candidate.location = .random(in: world)
      while snake.segments.contains(where: { $0.location == candidate.location }) {
        candidate.location = .random(in: world)
      }
      food.append(candidate)
    }
  }

  var queuedInputs: [Snake.Direction] = []

  func turn(_ newDirection: Snake.Direction) {
    let effectiveDirection = queuedInputs.last ?? snake.direction
    let isQueued = queuedInputs.last != nil
    if canTurn(from: effectiveDirection, to: newDirection) {
      queuedInputs.append(newDirection)
    } else {
      print("Can't turn from \(effectiveDirection) (queued: \(isQueued) to \(newDirection)")
    }
  }

  func canTurn(from direction1: Snake.Direction, to direction2: Snake.Direction) -> Bool {
    switch (direction1, direction2) {
    case (.left, .up), (.left, .down), (.up, .right), (.up, .left), (.right, .up), (.right, .down),
      (.down, .right), (.down, .left):
      return true
    default: return false
    }
  }

  func step() {

    if let queuedDirection = queuedInputs.first {
      queuedInputs.removeFirst()
      snake.direction = queuedDirection
    }

    guard let head = snake.head?.location else {
      print("Cannot move headless snake.")
      return
    }

    let newHead: Location =
      switch snake.direction {
      case .left: head.offset(x: -1)
      case .right: head.offset(x: 1)
      case .up: head.offset(y: -1)
      case .down: head.offset(y: 1)
      }

    print("New head is \(newHead)")

    guard isInBounds(newHead) else {
      print("New head is out of bounds")
      return
    }

    snake.segments.append(.init(location: newHead))

    if let foodIndex = food.firstIndex(where: { $0.location == newHead }) {
      food.remove(at: foodIndex)
      placeFood(count: 1)
    } else {
      snake.segments.removeFirst()
    }
  }

  func isInBounds(_ location: Location) -> Bool {
    location.x >= 0 && location.x < world.width && location.y >= 0 && location.y < world.height
  }
}

struct ContentView: View {

  let model: GameModel

  @State private var timer = Timer.publish(every: 1.0 / 8.0, on: .main, in: .common).autoconnect()
  @FocusState private var focused

  var body: some View {
    VStack {
      Color.black
        .frame(width: 640, height: 640)
        .overlay {
          GeometryReader { proxy in
            SnakeView(snake: model.snake, world: model.world, bounds: proxy)
            ForEach(model.food, id: \.self) { food in
              FoodView(food: food, world: model.world, bounds: proxy)
            }
          }
        }
    }
    .padding()
    .onReceive(timer) { _ in
      model.step()
    }
    .focusable()
    .onAppear {
      focused = true
    }
    .onKeyPress { key in
      switch key.key {
      case .leftArrow: model.turn(.left)
      case .rightArrow: model.turn(.right)
      case .upArrow: model.turn(.up)
      case .downArrow: model.turn(.down)
      default:
        return .ignored
      }
      return .handled
    }
  }
}

struct FoodView: View {
  let food: GameModel.Food
  let world: GameModel.World
  let bounds: GeometryProxy

  var body: some View {
    let h = bounds.size.height
    let w = bounds.size.width
    let rows = world.height
    let cols = world.width
    let block = CGSize(width: w / cols.f, height: h / rows.f)
    Circle()
      .fill(.red)
      .frame(width: block.width, height: block.height)
      .offset(x: food.location.x.f * block.width, y: food.location.y.f * block.height)
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
      if let head = snake.head?.location {
        p.move(to: CGPoint(x: head.x, y: head.y).scaled(by: block))
        p.addLine(to: CGPoint(x: head.x, y: head.y).scaled(by: block))
        for segment in snake.segments.dropLast().reversed().map(\.location) {
          p.addLine(to: CGPoint(x: segment.x, y: segment.y).scaled(by: block))
        }
      }
    }
    .offset(x: block.width * 0.5, y: block.height * 0.5)
    .stroke(style: StrokeStyle(lineWidth: block.longerSize, lineCap: .round, lineJoin: .round))
    .foregroundStyle(Color.green)
  }
}

extension Int {
  var f: Double {
    Double(self)
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

extension Location {
  static func random(in world: GameModel.World) -> Self {
    var location = Location()
    location.x = Int.random(in: 0..<world.width)
    location.y = Int.random(in: 0..<world.height)
    return location
  }

  func offset(x: Int = 0, y: Int = 0) -> Self {
    Self(x: self.x + x, y: self.y + y)
  }
}

#Preview {
  ContentView(
    model: {
      let model = GameModel()
      model.snake.segments = [
        .init(location: Location(x: 0, y: 0)),
        .init(location: Location(x: 1, y: 0)),
        .init(location: Location(x: 1, y: 1)),
      ]
      model.placeFood(count: 200)
      return model
    }()
  )
}
