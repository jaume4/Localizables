// localizablesTests.swift
// Localizables

@testable import LocalizablesCore
import XCTest

final class LocalizablesTests: XCTestCase {
    func testLocalizableLineParser() throws {
        let testKey = "This_is_a_key"

        let testValue = #"""
        \"Escaped\n\\\"\"\"input\"
        line
        new line
        """#

        let comment = "  // comment"

        var input = """
        "\(testKey)" = "\(testValue)" ;\(comment)
        """[...]

        let (key, value) = try LocalizableLineParser().parse(&input)

        XCTAssertEqual(key, testKey)
        XCTAssertEqual(value, testValue)
        XCTAssertEqual(input, comment[...])
    }

    func testLocalizablesParserFailsOnBadInput() throws {
        let badInputs = [
            #""key = "value";"#,
            #"key = "value";"#,
            #""key" = "value;"#,
            #""key" = value";"#,
            #""key" "value";"#,
            #""key" = "value""#,
            #""key" = " "value";"#,
            """
            "key" = "value";
            "fail" = "novalue"
            "miss" = "yes"
            """,
        ]

        XCTAssertThrowsError(try LocalizablesParser.parse(from: badInputs[0]))
        XCTAssertThrowsError(try LocalizablesParser.parse(from: badInputs[1]))
        XCTAssertThrowsError(try LocalizablesParser.parse(from: badInputs[2]))
        XCTAssertThrowsError(try LocalizablesParser.parse(from: badInputs[3]))
        XCTAssertThrowsError(try LocalizablesParser.parse(from: badInputs[4]))
        XCTAssertThrowsError(try LocalizablesParser.parse(from: badInputs[5]))
        XCTAssertThrowsError(try LocalizablesParser.parse(from: badInputs[6]))
        XCTAssertThrowsError(try LocalizablesParser.parse(from: badInputs[7]))
    }

    func testLocalizablesParser() throws {
        let testValue = #"\"Escaped\n\\\"\"\"input\"linenew line"# +
            """
            line1
            line2
            """

        let testString = """
        /*
            TEST COMMMENT

        */

        // more comments

        "key1" = "value1";
        "key2"= "//value2"    ;// end comment
        /* line comment */
        // more
        "key3" ="value3" ;// line at end

        "key_4" = "value4";
        "key5" ="\(testValue)"; // comment
        /* more*/
        "key6"   =    "value6
        with line";
        "key7"="value7"     ;

        """

        let literals = try LocalizablesParser.parse(from: testString)
        XCTAssertEqual(literals.count, 7)
        XCTAssertEqual(literals[0].key, "key1")
        XCTAssertEqual(literals[0].value, "value1")

        XCTAssertEqual(literals[1].key, "key2")
        XCTAssertEqual(literals[1].value, "//value2")

        XCTAssertEqual(literals[2].key, "key3")
        XCTAssertEqual(literals[2].value, "value3")

        XCTAssertEqual(literals[3].key, "key_4")
        XCTAssertEqual(literals[3].value, "value4")

        XCTAssertEqual(literals[4].key, "key5")
        XCTAssertEqual(literals[4].value, testValue)

        XCTAssertEqual(literals[5].key, "key6")
        XCTAssertEqual(literals[5].value, "value6\nwith line")

        XCTAssertEqual(literals[6].key, "key7")
        XCTAssertEqual(literals[6].value, "value7")
    }
    }
}
