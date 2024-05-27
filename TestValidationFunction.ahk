; Test for ValidationFunction
Test_ValidationFunction()
{
    ; Test case 1: Empty options, empty trigger, empty replacement
    result := ValidationFunction("", "", "")
    expected := "OPTIONS BOX `n-Okay.*|*HOTSTRING BOX `n-HotString box should not be empty.*|*REPLACEMENT BOX `n-Replacement string box should not be empty."
    AssertEqual(result, expected, "Test case 1 failed")

    ; Test case 2: Valid options, empty trigger, empty replacement
    result := ValidationFunction("C", "", "")
    expected := "OPTIONS BOX `n-Okay.*|*HOTSTRING BOX `n-HotString box should not be empty.*|*REPLACEMENT BOX `n-Replacement string box should not be empty."
    AssertEqual(result, expected, "Test case 2 failed")

    ; Test case 3: Empty options, valid trigger, empty replacement
    result := ValidationFunction("", "myTrigger", "")
    expected := "OPTIONS BOX `n-Okay.*|*HOTSTRING BOX `n-Okay.*|*REPLACEMENT BOX `n-Replacement string box should not be empty."
    AssertEqual(result, expected, "Test case 3 failed")

    ; Test case 4: Empty options, empty trigger, valid replacement
    result := ValidationFunction("", "", "myReplacement")
    expected := "OPTIONS BOX `n-Okay.*|*HOTSTRING BOX `n-HotString box should not be empty.*|*REPLACEMENT BOX `n-Okay."
    AssertEqual(result, expected, "Test case 4 failed")

    ; Test case 5: Valid options, valid trigger, valid replacement
    result := ValidationFunction("C", "myTrigger", "myReplacement")
    expected := "OPTIONS BOX `n-Okay.*|*HOTSTRING BOX `n-Okay.*|*REPLACEMENT BOX `n-Okay."
    AssertEqual(result, expected, "Test case 5 failed")
}

; Helper function to assert equality
AssertEqual(actual, expected, message)
{
    if (actual = expected)
        MsgBox("PASS: " . message)
    else
        MsgBox("FAIL: " . message . "`nExpected: " . expected . "`nActual: " . actual)
}

; Run the test unit
Test_ValidationFunction()