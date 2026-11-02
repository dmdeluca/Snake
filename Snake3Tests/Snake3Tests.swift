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
}
