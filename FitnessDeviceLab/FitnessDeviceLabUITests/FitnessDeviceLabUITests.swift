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
        let addVirtual = app.buttons["add_virtual_device"]
        if addVirtual.waitForExistence(timeout: 5) {
            addVirtual.tap()
            addVirtual.tap()
        }
        
        // Connect the virtual devices
        let connectButton1 = app.buttons["connect_button_virtual_trainer_1"]
        if connectButton1.waitForExistence(timeout: 5) {
            connectButton1.tap()
        }
        
        let connectButton2 = app.buttons["connect_button_virtual_trainer_2"]
        if connectButton2.waitForExistence(timeout: 5) {
            connectButton2.tap()
        }
        
        takeScreenshot(name: "1_Devices_Tab")

        // 2. Library Tab
        let libraryTab = app.buttons["Library"]
        let tabLibrary = app.descendants(matching: .any).matching(identifier: "tab_library").firstMatch
        
        if libraryTab.exists && libraryTab.isHittable {
            libraryTab.tap()
        } else if tabLibrary.exists && tabLibrary.isHittable {
            tabLibrary.tap()
        } else {
            // Check for Sidebar toggle on iPad/Mac if hidden
            let sidebarButton = app.buttons["Sidebar"]
            if sidebarButton.exists {
                sidebarButton.tap()
            }
            
            if tabLibrary.waitForExistence(timeout: 2) {
                tabLibrary.tap()
            } else if app.staticTexts["Library"].exists {
                app.staticTexts["Library"].firstMatch.tap()
            } else {
                XCTFail("Could not find Library tab")
            }
        }
        takeScreenshot(name: "2_Library_Tab")

        // 3. Workout Tab (Setup)
        let workoutTab = app.buttons["Workout"]
        let tabWorkout = app.descendants(matching: .any).matching(identifier: "tab_workout").firstMatch
        
        if workoutTab.exists && workoutTab.isHittable {
            workoutTab.tap()
        } else if tabWorkout.exists && tabWorkout.isHittable {
            tabWorkout.tap()
        } else {
            let sidebarButton = app.buttons["Sidebar"]
            if sidebarButton.exists {
                sidebarButton.tap()
            }
            
            if tabWorkout.waitForExistence(timeout: 2) {
                tabWorkout.tap()
            } else if app.staticTexts["Workout"].exists {
                app.staticTexts["Workout"].firstMatch.tap()
            } else {
                XCTFail("Could not find Workout tab")
            }
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
            // Check for Sidebar on iPad/Mac
            let sidebarButton = app.buttons["Sidebar"]
            if sidebarButton.exists {
                sidebarButton.tap()
            }
            app.staticTexts["Settings"].firstMatch.tap()
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
