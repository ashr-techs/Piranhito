//
//  Piranhito.swift
//  Piranhito
//
//  Created by Mauro Antonio Giacomello on 19/02/2020.
//  The name of MAURO ANTONIO GIACOMELLO may not be used to endorse or promote
//  products derived from this software without specific prior written permission.
/*******************************************************************************
*
* The MIT License (MIT)
*
* Copyright (c) 2020, 2021, 2022  Mauro Antonio Giacomello
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*******************************************************************************/
//

import Foundation

enum OptionType: String {
  case palindrome = "p"
  case anagram = "a"
  case help = "h"
  case quit = "q"
  case project = "x"
  case unknown
  
  init(value: String) {
    switch value {
    case "a": self = .anagram
    case "p": self = .palindrome
    case "h": self = .help
    case "q": self = .quit
    case "x": self = .project
    default: self = .unknown
    }
  }
}

class Piranhito {
  
  let consoleIO = ConsoleIO()
  
  func staticMode() {
    let argCount = CommandLine.argc
    let argument = CommandLine.arguments[1]
    let (option, value) = getOption(argument.substring(from: argument.index(argument.startIndex, offsetBy: 1)))
    
    //1
    switch option {
    case .anagram:
      //2
      if argCount != 4 {
        if argCount > 4 {
          consoleIO.writeMessage("Too many arguments for option \(option.rawValue)", to: .error)
        } else {
          consoleIO.writeMessage("Too few arguments for option \(option.rawValue)", to: .error)
        }
        consoleIO.printUsage()
      } else {
        //3
        let first = CommandLine.arguments[2]
        let second = CommandLine.arguments[3]
        
        if first.isAnagramOf(second) {
          consoleIO.writeMessage("\(second) is an anagram of \(first)")
        } else {
          consoleIO.writeMessage("\(second) is not an anagram of \(first)")
        }
      }
    case .palindrome:
      //4
      if argCount != 3 {
        if argCount > 3 {
          consoleIO.writeMessage("Too many arguments for option \(option.rawValue)", to: .error)
        } else {
          consoleIO.writeMessage("Too few arguments for option \(option.rawValue)", to: .error)
        }
        consoleIO.printUsage()
      } else {
        //5
        let s = CommandLine.arguments[2]
        let isPalindrome = s.isPalindrome()
        consoleIO.writeMessage("\(s) is \(isPalindrome ? "" : "not ")a palindrome")
      }
    //6
    case .help:
      consoleIO.printUsage()
      
    case .project:
        consoleIO.writeMessage("project \(value)")
        consoleIO.printUsage()
      
    case .unknown, .quit:
      //7
      consoleIO.writeMessage("Unknown option \(value)")
      consoleIO.printUsage()
    }
  }
  
  func getOption(_ option: String) -> (option:OptionType, value: String) {
    return (OptionType(value: option), option)
  }
  
  func interactiveMode() {
    //1
    consoleIO.writeMessage("Welcome to Panagram. This program checks if an input string is an anagram or palindrome.")
    //2
    var shouldQuit = false
    while !shouldQuit {
      //3
      consoleIO.writeMessage("Type 'a' to check for anagrams or 'p' for palindromes type 'q' to quit.")
      let (option, value) = getOption(consoleIO.getInput())
      
      switch option {
      case .anagram:
        //4
        consoleIO.writeMessage("Type the first string:")
        let first = consoleIO.getInput()
        consoleIO.writeMessage("Type the second string:")
        let second = consoleIO.getInput()
        
        //5
        if first.isAnagramOf(second) {
          consoleIO.writeMessage("\(second) is an anagram of \(first)")
        } else {
          consoleIO.writeMessage("\(second) is not an anagram of \(first)")
        }
      case .palindrome:
        consoleIO.writeMessage("Type a word or sentence:")
        let s = consoleIO.getInput()
        let isPalindrome = s.isPalindrome()
        consoleIO.writeMessage("\(s) is \(isPalindrome ? "" : "not ")a palindrome")
        
      case .quit:
        shouldQuit = true
        
      default:
        //6
        consoleIO.writeMessage("Unknown option \(value)", to: .error)
      }
    }
  }
}
