//
//  StringExtension.swift
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

extension String {
  func isAnagramOf(_ s: String) -> Bool {
    //1
    let lowerSelf = self.lowercased().replacingOccurrences(of: " ", with: "")
    let lowerOther = s.lowercased().replacingOccurrences(of: " ", with: "")
    //2
    return lowerSelf.sorted() == lowerOther.sorted()
  }
  
  func isPalindrome() -> Bool {
    //1
    let f = self.lowercased().replacingOccurrences(of: " ", with: "")
    //2
    let s = String(f.reversed())
    //3
    return  f == s
  }
}
