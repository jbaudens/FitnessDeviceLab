import XCTest

final class FitnessDeviceLabUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    @MainActor
    func testUserWalkthrough() throws {
        // 1. Devices Tab (Initial screen)
        // Add virtual sensors to simulate a user setup
        let addVirtual = app.buttons["Add Virtual"]
        if addVirtual.waitForExistence(timeout: 5) {
            addVirtual.tap()
            addVirtual.tap()
        }
        
        // Connect the virtual devices
        let connectButtons = app.buttons.matching(identifier: "Connect")
        if connectButtons.element(boundBy: 0).waitForExistence(timeout: 2) {
            connectButtons.element(boundBy: 0).tap()
        }
        // After connecting the first, the second one is now at index 0 of "Connect" buttons
        if connectButtons.element(boundBy: 0).waitForExistence(timeout: 2) {
            connectButtons.element(boundBy: 0).tap()
        }
        
        takeScreenshot(name: "1_Devices_Tab")

        // 2. Library Tab
        let libraryTab = app.buttons["Library"]
        if libraryTab.exists {
            libraryTab.tap()
        } else {
            app.staticTexts["Library"].tap()
        }
        takeScreenshot(name: "2_Library_Tab")

        // 3. Workout Tab (Setup)
        let workoutTab = app.buttons["Workout"]
        if workoutTab.exists {
            workoutTab.tap()
        } else {
            app.staticTexts["Workout"].tap()
        }

        // Wait for setup screen
        XCTAssertTrue(app.staticTexts["Workout Setup"].waitForExistence(timeout: 5))
        takeScreenshot(name: "3_Workout_Setup_Initial")

        // Try to select sensors for SET A
        let hrPickerA = app.buttons["hr_picker_a"]
        if hrPickerA.waitForExistence(timeout: 5) {
            hrPickerA.tap()
            let virtual1 = app.buttons["Virtual Trainer 1"]
            if virtual1.waitForExistence(timeout: 2) {
                virtual1.tap()
            }
        }

        let pwrPickerA = app.buttons["pwr_picker_a"]
        if pwrPickerA.waitForExistence(timeout: 5) {
            pwrPickerA.tap()
            let virtual1 = app.buttons["Virtual Trainer 1"]
            if virtual1.waitForExistence(timeout: 2) {
                virtual1.tap()
            }
        }

        // Try to select sensors for SET B
        let hrPickerB = app.buttons["hr_picker_b"]
        if hrPickerB.waitForExistence(timeout: 5) {
            if !hrPickerB.isHittable {
                app.swipeUp()
            }
            hrPickerB.tap()
            let virtual2 = app.buttons["Virtual Trainer 2"]
            if virtual2.waitForExistence(timeout: 2) {
                virtual2.tap()
            }
        }

        let pwrPickerB = app.buttons["pwr_picker_b"]
        if pwrPickerB.waitForExistence(timeout: 5) {
            if !pwrPickerB.isHittable {
                app.swipeUp()
            }
            pwrPickerB.tap()
            let virtual2 = app.buttons["Virtual Trainer 2"]
            if virtual2.waitForExistence(timeout: 2) {
                virtual2.tap()
            }
        }
        takeScreenshot(name: "3_Workout_Setup_Configured")

        // 4. Start Workout (Active Lab Mode)
        let startButton = app.buttons["Start Free Ride"]
        if startButton.waitForExistence(timeout: 5) {
            startButton.tap()
        }        
        // Wait for workout to start and dashboard to load
        XCTAssertTrue(app.staticTexts["SET A"].waitForExistence(timeout: 5))
        
        // Wait a bit for charts to populate
        sleep(2)
        takeScreenshot(name: "4_Active_Workout_LabMode")
        
        // 5. Settings Tab
        let settingsTab = app.buttons["Settings"]
        if settingsTab.exists {
            settingsTab.tap()
        } else {
            app.staticTexts["Settings"].tap()
        }
        takeScreenshot(name: "5_Settings_Tab")
    }

    private func takeScreenshot(name: String) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
