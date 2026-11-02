//
//  Snake3Tests.swift
//  Snake3Tests
//
//  Created by David DeLuca on 11/1/26.
//

import OrderedCollections
import Testing

@testable import Snake3

struct Snake3Tests {

  @Test @MainActor func `placing 5 foods results in 5 distinct food placements`() async throws {
    let model = GameModel()
    model.placeFood(count: 5)
    #expect(model.food.count == 5)
  }

  @Test @MainActor func `placing food does not overlap food with snake`() async throws {
    let model = GameModel()
    model.snake.segments = OrderedSet(
      (0..<10).map { i in
        .init(location: Location(x: i, y: 0))
      }
    )
    model.placeFood(count: 50)
    #expect(model.food.count == 50)
    #expect(
      model.food.allSatisfy { fd in
        model.snake.segments.allSatisfy { seg in
          fd.location != seg.location
        }
      }
    )
  }

  @Test @MainActor func `placing a huge amount of food does not crash or hang`() async throws {
    let model = GameModel()
    model.snake.segments = OrderedSet(
      (0..<10).map { i in
        .init(location: Location(x: i, y: 0))
      }
    )
    model.placeFood(count: 50000)
    #expect(model.food.count == model.world.width * model.world.height - model.snake.segments.count)
  }

  @Test @MainActor func `valid turns`() async throws {
    let model = GameModel()
    #expect(model.canTurn(from: .down, to: .right) == true)
    #expect(model.canTurn(from: .down, to: .left) == true)
    #expect(model.canTurn(from: .up, to: .right) == true)
    #expect(model.canTurn(from: .up, to: .left) == true)
    #expect(model.canTurn(from: .right, to: .up) == true)
    #expect(model.canTurn(from: .right, to: .down) == true)
    #expect(model.canTurn(from: .left, to: .up) == true)
    #expect(model.canTurn(from: .left, to: .down) == true)
  }

  @Test @MainActor func `invalid turns`() async throws {
    let model = GameModel()
    #expect(model.canTurn(from: .down, to: .down) == false)
    #expect(model.canTurn(from: .up, to: .up) == false)
    #expect(model.canTurn(from: .right, to: .right) == false)
    #expect(model.canTurn(from: .left, to: .left) == false)
    #expect(model.canTurn(from: .down, to: .up) == false)
    #expect(model.canTurn(from: .up, to: .down) == false)
    #expect(model.canTurn(from: .right, to: .left) == false)
    #expect(model.canTurn(from: .left, to: .right) == false)
  }

  @Test @MainActor func `snake moves right`() async throws {
    let model = GameModel()
    model.snake = .init(origin: Location(x: 0, y: 0))
      .extend(.right, count: 2)
    model.snake.direction = .right
    model.step()
    #expect(
      model.snake.segments.map(\.location) == [
        Location(x: 1, y: 0),
        Location(x: 2, y: 0),
        Location(x: 3, y: 0),
      ]
    )
  }

  @Test @MainActor func `snake moves down`() async throws {
    let model = GameModel()
    model.snake = .init(origin: Location(x: 0, y: 0))
      .extend(.right, count: 2)
    model.snake.direction = .down
    model.step()
    #expect(
      model.snake.segments.map(\.location) == [
        Location(x: 1, y: 0),
        Location(x: 2, y: 0),
        Location(x: 2, y: 1),
      ]
    )
  }

  @Test @MainActor func `snake moves up`() async throws {
    let model = GameModel()
    model.snake = .init(origin: Location(x: 0, y: 1))
      .extend(.right, count: 2)
    model.snake.direction = .up
    model.step()
    #expect(
      model.snake.segments.map(\.location) == [
        Location(x: 1, y: 1),
        Location(x: 2, y: 1),
        Location(x: 2, y: 0),
      ]
    )
  }

  @Test @MainActor func `snake moves left`() async throws {
    let model = GameModel()
    model.snake = .init(origin: Location(x: 3, y: 1))
      .extend(.left, count: 2)
    model.snake.direction = .left
    model.step()
    #expect(
      model.snake.segments.map(\.location) == [
        Location(x: 2, y: 1),
        Location(x: 1, y: 1),
        Location(x: 0, y: 1),
      ]
    )
  }
  
  @Test @MainActor func `world contains locations`() async throws {
    let world = World(width: 5, height: 5)
    #expect(world.contains(Location(x:0,y:0)) == true)
    #expect(world.contains(Location(x:0,y:1)) == true)
    #expect(world.contains(Location(x:1,y:0)) == true)
    #expect(world.contains(Location(x:4,y:4)) == true)
    #expect(world.contains(Location(x:3,y:4)) == true)
    #expect(world.contains(Location(x:4,y:3)) == true)
    #expect(world.contains(Location(x:5,y:4)) == false)
    #expect(world.contains(Location(x:5,y:5)) == false)
    #expect(world.contains(Location(x:4,y:5)) == false)
  }
}
