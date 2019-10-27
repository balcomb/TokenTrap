//
//  MenuViewTests.swift
//  TokenTrapTests
//
//  Created by Ben Balcomb on 10/26/19.
//  Copyright © 2019 Ben Balcomb. All rights reserved.
//

import XCTest
@testable import TokenTrap

class MenuViewTests: TokenTrapTests {

    let viewControllerMock = MenuViewControllerMock()

    func testHandlePlayTap() {
        viewControllerMock.handlePlayTapWasCalled = false
        MenuView(viewController: viewControllerMock).handlePlayTap(button: UIButton())
        XCTAssertTrue(viewControllerMock.handlePlayTapWasCalled)
    }

    func testHandleLearnTap() {
        viewControllerMock.handleLearnTapWasCalled = false
        MenuView(viewController: viewControllerMock).handleLearnTap(button: UIButton())
        XCTAssertTrue(viewControllerMock.handleLearnTapWasCalled)
    }

    func testHandleTrainTap() {
        viewControllerMock.handleTrainTapWasCalled = false
        MenuView(viewController: viewControllerMock).handleTrainTap(button: UIButton())
        XCTAssertTrue(viewControllerMock.handleTrainTapWasCalled)
    }

    func testHandleSkillChange() {
        viewControllerMock.isExpertMode = true
        let control = UISegmentedControl(items: ["0", "1"])
        control.selectedSegmentIndex = 0
        MenuView(viewController: viewControllerMock).handleSkillChange(control: control)
        XCTAssertFalse(viewControllerMock.isExpertMode)

        control.selectedSegmentIndex = 1
        MenuView(viewController: viewControllerMock).handleSkillChange(control: control)
        XCTAssertTrue(viewControllerMock.isExpertMode)
    }

}

class MenuViewControllerMock: MenuViewController {
    var handlePlayTapWasCalled = false
    var handleLearnTapWasCalled = false
    var handleTrainTapWasCalled = false

    override func handlePlayTap() {
        handlePlayTapWasCalled = true
    }

    override func handleLearnTap() {
        handleLearnTapWasCalled = true
    }

    override func handleTrainTap() {
        handleTrainTapWasCalled = true
    }
}
