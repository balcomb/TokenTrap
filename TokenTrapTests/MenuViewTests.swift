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
        MenuView(viewController: viewControllerMock).handlePlayTap()
        XCTAssertTrue(viewControllerMock.handlePlayTapWasCalled)
    }

    func testHandleLearnTap() {
        viewControllerMock.handleLearnTapWasCalled = false
        MenuView(viewController: viewControllerMock).handleLearnTap()
        XCTAssertTrue(viewControllerMock.handleLearnTapWasCalled)
    }

    func testHandleTrainTap() {
        viewControllerMock.handleTrainTapWasCalled = false
        MenuView(viewController: viewControllerMock).handleTrainTap()
        XCTAssertTrue(viewControllerMock.handleTrainTapWasCalled)
    }

    func testHandleSkillChange() {
        viewControllerMock.skillLevelDidChangeWasCalled = false
        MenuView(viewController: viewControllerMock).handleSkillChange()
        XCTAssertTrue(viewControllerMock.skillLevelDidChangeWasCalled)
    }

    func testRenderControls() {
        let menuView = MenuView(viewController: MenuViewController())
        menuView.renderControls()
        XCTAssertEqual(menuView.viewConstraints.activeConstraints, menuView.controlConstraints)
    }
}

class MenuViewControllerMock: MenuViewController {
    var handlePlayTapWasCalled = false
    var handleLearnTapWasCalled = false
    var handleTrainTapWasCalled = false
    var skillLevelDidChangeWasCalled = false

    override func handlePlayTap() {
        handlePlayTapWasCalled = true
    }

    override func handleLearnTap() {
        handleLearnTapWasCalled = true
    }

    override func handleTrainTap() {
        handleTrainTapWasCalled = true
    }

    override func skillLevelDidChange(expertModeOn: Bool) {
        skillLevelDidChangeWasCalled = true
    }
}
