local lib = require("neotest.lib")

describe("When receiving valid XML", function()
  it("it is parsed correctly", function()
    local xml_data = [[<?xml version="1.0" encoding="UTF-8"?>
<testsuites>
  <testsuite name="TestProject\UserTest" file="my_file" tests="1" assertions="3" errors="0" warnings="0" failures="0" skipped="0" time="0.000923">
    <testcase name="testClassConstructor" class="TestProject\UserTest" classname="TestProject.UserTest" file="my_file" line="13" assertions="3" time="0.000923"/>
  </testsuite>
</testsuites>]]

    local expected = {
      testsuites = {
        testsuite = {
          _attr = {
            assertions = "3",
            errors = "0",
            failures = "0",
            file = "my_file",
            name = "TestProject\\UserTest",
            skipped = "0",
            tests = "1",
            time = "0.000923",
            warnings = "0",
          },
          testcase = {
            _attr = {
              assertions = "3",
              class = "TestProject\\UserTest",
              classname = "TestProject.UserTest",
              file = "my_file",
              line = "13",
              name = "testClassConstructor",
              time = "0.000923",
            },
          },
        },
      },
    }

    assert.are.same(lib.xml.parse(xml_data), expected)
  end)
end)
