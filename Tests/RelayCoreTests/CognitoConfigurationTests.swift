import XCTest

@testable import RelayCore

final class CognitoConfigurationTests: XCTestCase {
  func testDeploymentMustBeConfigured() {
    XCTAssertThrowsError(try CognitoConfiguration.load(info: [:], environment: [:]))
    XCTAssertThrowsError(
      try CognitoConfiguration(clientID: "bad client", loginURL: "https://auth.example.invalid"))
  }

  func testRejectsUnsafeLoginDestinations() {
    for url in [
      "http://auth.example.invalid", "https://user:secret@auth.example.invalid",
      "https://auth.example.invalid?token=test", "https://auth.example.invalid/oauth2/token",
    ] {
      XCTAssertThrowsError(try CognitoConfiguration(clientID: "testclient123", loginURL: url))
    }
  }

  func testLoadsAppConfiguration() throws {
    let config = try CognitoConfiguration.load(
      info: [
        "RELAYCognitoClientID": "appclient123",
        "RELAYCognitoLoginURL": "https://auth.example.invalid",
      ], environment: [:])
    XCTAssertEqual(config.clientID, "appclient123")
    XCTAssertEqual(config.loginURL.host, "auth.example.invalid")
  }

  func testCLIEnvironmentOverridesBundle() throws {
    let config = try CognitoConfiguration.load(
      info: ["RELAYCognitoClientID": "oldclient"],
      environment: [
        "RELAY_COGNITO_CLIENT_ID": "newclient",
        "RELAY_COGNITO_LOGIN_URL": "https://auth.example.invalid",
      ])
    XCTAssertEqual(config.clientID, "newclient")
  }
}
