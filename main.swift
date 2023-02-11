//
//  main.swift
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

protocol FileRepository {
    func read(from path: String) throws -> String
    func readAsync(from path: String, completion: @escaping (Result<String, Error>) -> Void)
    func write(_ string: String, to path: String) throws
    func writeAsync(_ string: String, to path: String, completion: @escaping (Result<Void, Error>) -> Void)
}



class DefaultFileRepository {
    
    // MARK: Properties
    
    let queue: DispatchQueue = .global()
    let fileManager: FileManager = .default
    lazy var baseURL: URL = {
        try! fileManager
            .url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("MyFiles")
    }()
    
    
    // MARK: Private functions
    
    private func doRead(from path: String) throws -> String {
        let url = baseURL.appendingPathComponent(path)
        
        var isDir: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDir) && !isDir.boolValue else {
            throw ReadWriteError.doesNotExist
        }
        
        let string: String
        do {
            string = try String(contentsOf: url)
        } catch {
            throw ReadWriteError.readFailed(error)
        }
        
        return string
    }
    
    private func doWrite(_ string: String, to path: String) throws {
        let url = baseURL.appendingPathComponent(path)
        let folderURL = url.deletingLastPathComponent()
        
        var isFolderDir: ObjCBool = false
        if fileManager.fileExists(atPath: folderURL.path, isDirectory: &isFolderDir) {
            if !isFolderDir.boolValue {
                throw ReadWriteError.canNotCreateFolder
            }
        } else {
            do {
                try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
            } catch {
                throw ReadWriteError.canNotCreateFolder
            }
        }
        
        var isDir: ObjCBool = false
        guard !fileManager.fileExists(atPath: url.path, isDirectory: &isDir) || !isDir.boolValue else {
            throw ReadWriteError.canNotCreateFile
        }
        
        guard let data = string.data(using: .utf8) else {
            throw ReadWriteError.encodingFailed
        }
        
        do {
            try data.write(to: url)
        } catch {
            throw ReadWriteError.writeFailed(error)
        }
    }
    
}


extension DefaultFileRepository: FileRepository {
    func read(from path: String) throws -> String {
        try queue.sync { try self.doRead(from: path) }
    }
    
    func readAsync(from path: String, completion: @escaping (Result<String, Error>) -> Void) {
        queue.async {
            do {
                let result = try self.doRead(from: path)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func write(_ string: String, to path: String) throws {
        try queue.sync { try self.doWrite(string, to: path) }
    }
    
    func writeAsync(_ string: String, to path: String, completion: @escaping (Result<Void, Error>) -> Void) {
        queue.async {
            do {
                try self.doWrite(string, to: path)
                completion(.success(Void()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
}

enum ReadWriteError: LocalizedError {
    
    // MARK: Cases
    
    case doesNotExist
    case readFailed(Error)
    case canNotCreateFolder
    case canNotCreateFile
    case encodingFailed
    case writeFailed(Error)
}

extension NSRegularExpression {
    func matches(_ string: String) -> Bool {
        let range = NSRange(location: 0, length: string.utf16.count)
        return firstMatch(in: string, options: [], range: range) != nil
    }
}


extension StringProtocol {
    func ranges(of targetString: Self, options: String.CompareOptions = [], locale: Locale? = nil) -> [Range<String.Index>] {

        let result: [Range<String.Index>] = self.indices.compactMap { startIndex in
            let targetStringEndIndex = index(startIndex, offsetBy: targetString.count, limitedBy: endIndex) ?? endIndex
            return range(of: targetString, options: options, range: startIndex..<targetStringEndIndex, locale: locale)
        }
        return result
    }
}
// Generating Random String
func randomString(prefix: String, length: Int) -> String {
    let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    let alphanum = "\(prefix)\(String((prefix.count..<length).map{ _ in letters.randomElement()! }))"
    return alphanum
}


public extension String {
    
    //right is the first encountered string after left
    func between(_ left: String, _ right: String) -> String? {
        guard
            let leftRange = range(of: left), let rightRange = range(of: right, options: .backwards)
            , leftRange.upperBound <= rightRange.lowerBound
            else { return nil }
        
        let sub = self[leftRange.upperBound...]
        let closestToLeftRange = sub.range(of: right)!
        return String(sub[..<closestToLeftRange.lowerBound])
    }
    
    var length: Int {
        get {
            return self.count
        }
    }
    
    func substring(to : Int) -> String {
        let toIndex = self.index(self.startIndex, offsetBy: to)
        return String(self[...toIndex])
    }
    
    func substring(from : Int) -> String {
        let fromIndex = self.index(self.startIndex, offsetBy: from)
        return String(self[fromIndex...])
    }
    
    func substring(_ r: Range<Int>) -> String {
        let fromIndex = self.index(self.startIndex, offsetBy: r.lowerBound)
        let toIndex = self.index(self.startIndex, offsetBy: r.upperBound)
        let indexRange = Range<String.Index>(uncheckedBounds: (lower: fromIndex, upper: toIndex))
        return String(self[indexRange])
    }
    
    func character(_ at: Int) -> Character {
        return self[self.index(self.startIndex, offsetBy: at)]
    }
    
    func lastIndexOfCharacter(_ c: Character) -> Int? {
        guard let index = range(of: String(c), options: .backwards)?.lowerBound else
        { return nil }
        return distance(from: startIndex, to: index)
    }
}

func stringReplacer(_ progetto:String,_ source:String ) -> String {

    var baseline = source
    for prj in progetti {
        if (progetto == prj.id) {
            for twin in prj.replaceableStrings {
                if (twin[1].hasPrefix("@Random(")) {
                    var rs = randomString(prefix: "_", length: Int( Double( twin[1].between("(", ")") as! String)! ) )
                    baseline = baseline.replacingOccurrences(of: twin[0], with: rs)
                }else{
                    baseline = baseline.replacingOccurrences(of: twin[0], with: twin[1])
                }
            }
        }
    }
    
    return baseline
}


func copyrightReplacer(_ progetto:String,_ source:String ) -> String {

    var baseline = source
    for prj in progetti {
        if (progetto == prj.id) {
            for twin in prj.copyRightStrings {
                if (twin[1].hasPrefix("@Random(")) {
                    var rs = randomString(prefix: "_", length: Int( Double( twin[1].between("(", ")") as! String)! ) )
                    baseline = baseline.replacingOccurrences(of: twin[0], with: rs)
                }else{
                    baseline = baseline.replacingOccurrences(of: twin[0], with: twin[1])
                }
            }
        }
    }
    
    return baseline
}


func featuresRemover(_ progetto:String,_ source:String ) -> String {

    var removeTable:[[Int]] = [[]]
    var removeTable2:[[Any]] = [[]]
    
    // check formalities
    var baseline = source
    for prj in progetti {
        if (progetto == prj.id) {
            for feat in prj.removableFeatures {
                // esempio /*Piranhito?@-Tracer-S@O8gSAh@*/
                let SfullTkn = "/*Piranhito?@-\(feat.id)-S\(feat.eyecatcher)*/"     // Start
                let LfullTkn = "/*Piranhito?@-\(feat.id)-L\(feat.eyecatcher)*/"     // Leave
                let EfullTkn = "/*Piranhito?@-\(feat.id)-E\(feat.eyecatcher)*/"     // End
                
                if let sOff: Range<String.Index> = baseline.range(of: SfullTkn) {
                    let eOff: Int = baseline.distance(from: baseline.startIndex, to: sOff.lowerBound)
                    //print("index: ", eOff) //index: 2
                }
                
                let rangeS = baseline.ranges(of: SfullTkn)
                let rangeE = baseline.ranges(of: EfullTkn)
                
                let rangeL = baseline.ranges(of: LfullTkn)
                if (rangeL.count > 0){
                    print("eccoci ??? non so cosa possa servire... \(LfullTkn)")
                }
                                
                rangeS.forEach {
                    let v = "[\($0.lowerBound.utf16Offset(in: baseline)), \($0.upperBound.utf16Offset(in: baseline))]"
                    //print("[\($0.lowerBound.utf16Offset(in: baseline)), \($0.upperBound.utf16Offset(in: baseline))]")
                }
                rangeE.forEach {
                    let v = "[\($0.lowerBound.utf16Offset(in: baseline)), \($0.upperBound.utf16Offset(in: baseline))]"
                    //print("[\($0.lowerBound.utf16Offset(in: baseline)), \($0.upperBound.utf16Offset(in: baseline))]")
                }
                if (rangeS.count > 0 && rangeS.count == rangeE.count){
                    for (nr,r) in rangeS.enumerated() {
                        //print(rangeE[nr].upperBound.utf16Offset(in: baseline) - rangeS[nr].lowerBound.utf16Offset(in: baseline))
                        removeTable.append([rangeS[nr].lowerBound.utf16Offset(in: baseline),rangeE[nr].upperBound.utf16Offset(in: baseline) - rangeS[nr].lowerBound.utf16Offset(in: baseline)])
                        removeTable2.append([rangeS[nr].upperBound,rangeE[nr].lowerBound,rangeS[nr].upperBound.utf16Offset(in: baseline),rangeE[nr].lowerBound.utf16Offset(in: baseline)])
                    }
                }
    
            }
        }
    }
    if (removeTable.count > 0) {
        removeTable.forEach {
            var x = $0
            print(x)
        }
    }
    if (removeTable2.count > 0) {
        removeTable2.forEach {
            var x = $0
            print(x)
        }
    }
    
    // apply changes
    baseline = source
    for prj in progetti {
        if (progetto == prj.id) {
            for feat in prj.removableFeatures {
                
                // esempio /*Piranhito?@-Tracer-S@O8gSAh@*/
                let SfullTkn = "/*Piranhito?@-\(feat.id)-S\(feat.eyecatcher)*/"     // Start
                let LfullTkn = "/*Piranhito?@-\(feat.id)-L\(feat.eyecatcher)*/"     // Leave
                let EfullTkn = "/*Piranhito?@-\(feat.id)-E\(feat.eyecatcher)*/"     // End

                var between = baseline.between(SfullTkn, EfullTkn) // stackoverflow
                
                while (between != nil && between!.count > 0) {
                    
                    var elsewhere = try? between!.contains(LfullTkn)
                    if (elsewhere != nil && elsewhere == true ) {
                        print(elsewhere)
                        let k2bet:String = baseline.between(SfullTkn, LfullTkn)! // stackoverflow
                        let bet2 = "\(SfullTkn)\(k2bet)\(LfullTkn)"
                        //let bat2 = baseline.replacingOccurrences(of: bet2, with: "/*Piranhito?@-@FuncBegin@*/")
                        var bat2 = ""
                        if let send = baseline.range(of:bet2) {
                            bat2 = baseline.replacingCharacters(in: send, with: "/*Piranhito?@-@FuncBegin@*/" )
                         }
                        //baseline = bat2.replacingOccurrences(of: EfullTkn, with: "/*Piranhito?@-@FuncEnd@*/")
                        baseline = bat2
                        if let rend = bat2.range(of:EfullTkn) {
                            baseline = bat2.replacingCharacters(in: rend, with: "/*Piranhito?@-@FuncEnd@*/" )
                         }
                    }else{
                        let kbet:String = between!
                        let bet = "\(SfullTkn)\(kbet)\(EfullTkn)"
                        //let bat = baseline.replacingOccurrences(of: bet, with: "")
                        var bat = ""
                        if let send = baseline.range(of:bet) {
                             bat = baseline.replacingCharacters(in: send, with: "" )
                         }
                        baseline = bat
                    }
                    between = baseline.between(SfullTkn, EfullTkn) // stackoverflow
                }
                
            }
        }
    }
    
    return baseline
}


func copyrightAligner(_ progetto:String,_ source:String ) -> String {

    var removeTable:[[Int]] = [[]]
    var removeTable2:[[Any]] = [[]]
    
    // check formalities
    var baseline = source
    for prj in progetti {
        if (progetto == prj.id) {
            for feat in prj.copyRightFeatures {
                // esempio /*Piranhito?@-Tracer-S@O8gSAh@*/
                let SfullTkn = "/*Piranhito?@-\(feat.id)-S\(feat.eyecatcher)*/"     // Start
                let LfullTkn = "/*Piranhito?@-\(feat.id)-L\(feat.eyecatcher)*/"     // Leave
                let EfullTkn = "/*Piranhito?@-\(feat.id)-E\(feat.eyecatcher)*/"     // End
                
                if let sOff: Range<String.Index> = baseline.range(of: SfullTkn) {
                    let eOff: Int = baseline.distance(from: baseline.startIndex, to: sOff.lowerBound)
                    //print("index: ", eOff) //index: 2
                }
                
                let rangeS = baseline.ranges(of: SfullTkn)
                let rangeE = baseline.ranges(of: EfullTkn)
                
                let rangeL = baseline.ranges(of: LfullTkn)
                if (rangeL.count > 0){
                    print("eccoci ??? non so cosa possa servire... \(LfullTkn)")
                }
                                
                rangeS.forEach {
                    let v = "[\($0.lowerBound.utf16Offset(in: baseline)), \($0.upperBound.utf16Offset(in: baseline))]"
                    //print("[\($0.lowerBound.utf16Offset(in: baseline)), \($0.upperBound.utf16Offset(in: baseline))]")
                }
                rangeE.forEach {
                    let v = "[\($0.lowerBound.utf16Offset(in: baseline)), \($0.upperBound.utf16Offset(in: baseline))]"
                    //print("[\($0.lowerBound.utf16Offset(in: baseline)), \($0.upperBound.utf16Offset(in: baseline))]")
                }
                if (rangeS.count > 0 && rangeS.count == rangeE.count){
                    for (nr,r) in rangeS.enumerated() {
                        //print(rangeE[nr].upperBound.utf16Offset(in: baseline) - rangeS[nr].lowerBound.utf16Offset(in: baseline))
                        removeTable.append([rangeS[nr].lowerBound.utf16Offset(in: baseline),rangeE[nr].upperBound.utf16Offset(in: baseline) - rangeS[nr].lowerBound.utf16Offset(in: baseline)])
                        removeTable2.append([rangeS[nr].upperBound,rangeE[nr].lowerBound,rangeS[nr].upperBound.utf16Offset(in: baseline),rangeE[nr].lowerBound.utf16Offset(in: baseline)])
                    }
                }
    
            }
        }
    }
    if (removeTable.count > 0) {
        removeTable.forEach {
            var x = $0
            print(x)
        }
    }
    if (removeTable2.count > 0) {
        removeTable2.forEach {
            var x = $0
            print(x)
        }
    }
    
    // apply changes
    baseline = source
    for prj in progetti {
        if (progetto == prj.id) {
            for feat in prj.copyRightFeatures {
                
                // esempio /*Piranhito?@-Tracer-S@O8gSAh@*/
                let SfullTkn = "/*Piranhito?@-\(feat.id)-S\(feat.eyecatcher)*/"     // Start
                let LfullTkn = "/*Piranhito?@-\(feat.id)-L\(feat.eyecatcher)*/"     // Leave
                let EfullTkn = "/*Piranhito?@-\(feat.id)-E\(feat.eyecatcher)*/"     // End

                var between = baseline.between(SfullTkn, EfullTkn) // stackoverflow
                
                while (between != nil && between!.count > 0) {
                    
                    var elsewhere = try? between!.contains(LfullTkn)
                    if (elsewhere != nil && elsewhere == true ) {
                        print(elsewhere)
                        let k2bet:String = baseline.between(SfullTkn, LfullTkn)! // stackoverflow
                        let bet2 = "\(SfullTkn)\(k2bet)\(LfullTkn)"
                        //let bat2 = baseline.replacingOccurrences(of: bet2, with: "/*Piranhito?@-@FuncBegin@*/")
                        var bat2 = ""
                        if let send = baseline.range(of:bet2) {
                            bat2 = baseline.replacingCharacters(in: send, with: "/*Piranhito?@-@FuncBegin@*/" )
                         }
                        //baseline = bat2.replacingOccurrences(of: EfullTkn, with: "/*Piranhito?@-@FuncEnd@*/")
                        baseline = bat2
                        if let rend = bat2.range(of:EfullTkn) {
                            baseline = bat2.replacingCharacters(in: rend, with: "/*Piranhito?@-@FuncEnd@*/" )
                         }
                    }else{
                        let kbet:String = between!
                        let bet = "\(SfullTkn)\(kbet)\(EfullTkn)"
                        //let bat = baseline.replacingOccurrences(of: bet, with: "")
                        var bat = ""
                        if let send = baseline.range(of:bet) {
                             bat = baseline.replacingCharacters(in: send, with: "" )
                         }
                        baseline = bat
                    }
                    between = baseline.between(SfullTkn, EfullTkn) // stackoverflow
                }
                
            }
        }
    }
    
    return baseline
}

func featuresChecker(_ progetto:String,_ source:String ) -> String {

    var baseline = source
    for prj in progetti {
        if (progetto == prj.id) {
            for feat in prj.availableFeatures {
                
            }
        }
    }
    
    return baseline
}

func getTOD() -> String {
    
    // *** Create date ***
    let date = Date()

    // *** create calendar object ***
    var calendar = Calendar.current

    // *** Get components using current Local & Timezone ***
    print(calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date))

    // *** define calendar components to use as well Timezone to UTC ***
    calendar.timeZone = TimeZone(identifier: "UTC")!

    // *** Get All components from date ***
    let components = calendar.dateComponents([.hour, .year, .minute], from: date)
    print("All Components : \(components)")

    // *** Get Individual components from date ***
    let anno = calendar.component(.year, from: date)
    let mese = calendar.component(.month, from: date)
    let giorno = calendar.component(.day, from: date)
    let hour = calendar.component(.hour, from: date)
    let minutes = calendar.component(.minute, from: date)
    let seconds = calendar.component(.second, from: date)
    return("\(anno)/\(mese)/\(giorno)-\(hour):\(minutes):\(seconds)")
    
    
}

extension StringProtocol  {
    func substring<S: StringProtocol>(from start: S, options: String.CompareOptions = []) -> (SubSequence?, SubSequence?) {
        guard let lower = range(of: start, options: options)?.lowerBound
        else { return ( nil, nil ) }
        return ( self[..<lower], self[lower...] )
    }
    func substring<S: StringProtocol, T: StringProtocol>(from start: S, to end: T, options: String.CompareOptions = []) -> (SubSequence?, SubSequence?, SubSequence?) {
        guard let lower = range(of: start, options: options)?.upperBound,
            let upper = self[lower...].range(of: end, options: options)?.lowerBound
        else { return ( nil, nil, nil ) }
        return ( self[..<lower], self[lower..<upper], self[upper...] )
    }
}

func makeItBeauty(_ progetto:String,_ source:String ) -> String {

    var tmp = source
    
    //tmp = " func w(a ) { }  func z() { } if () { print(a) }  if a == b { } if ( \n \n\n\n\n\ \n c) { q}"
    
    var final = ""
    
    var _t = tmp.substring(from: "\n")
    while(_t.0 != nil && _t.1 != nil) {
        var sub0:String = String(_t.0!)
        var sub1:String = String(_t.1!)
        final = "\(final)\(sub0)"
        var not = false
        var nomore = true
        let _s = sub1.substring(from: "\n", to: "\n")
        if (_s.0 != nil && _s.1!.count > 0) {
            nomore = false
            var sub2:String = String(_s.0!)
            var sub3:String = String(_s.1!)
            var sub4:String = String(_s.2!)
            final = "\(final)\(sub2)"
            if (sub3.contains("\n")){
                //print(sub3);
            }
            for i in sub3 {
                if (i == " ") {
                    //ok
                }else{
                    not = true
                    break
                }
            }
            if (!not){
                let t = "(\(sub3))"
                sub3 = t
                sub3 = sub3.replacingOccurrences(of: t, with: "")
            }
            final = "\(final)\(sub3)"
            sub1 = sub4
        }
        if (nomore) {
            final = "\(final)\(sub1)"
            _t = sub1.substring(from: "nvfh98237238453455%/%/&()YHUIGFV") //force-end
        }else{
            _t = sub1.substring(from: ")")
            if (_t.0 == nil || _t.1 == nil){
                final = "\(final)\(sub1)"
            }
        }
    }
    
    while (final.contains("\n\n")) { final = final.replacingOccurrences(of: "\n\n",  with: "\n") }
    
    return final
    
    
}

func reformatter(_ progetto:String,_ source:String ) -> String {
    
    //let substr = string.substring(from: "'")                   // "Info/99/something', 'City Hall',1, 99);"
    //let subString = string.substring(from: "'", to: "',")  // "Info/99/something"

    var tmp = source
    
    //tmp = " func w(a ) { }  func z() { } if () { print(a) }  if a == b { } if ( \n \n c) { q}"
    
    var final = ""
    
    var _t = tmp.substring(from: "(")
    while(_t.0 != nil && _t.1 != nil) {
        var sub0:String = String(_t.0!)
        var sub1:String = String(_t.1!)
        final = "\(final)\(sub0)"
        var not = false
        var nomore = true
        let _s = sub1.substring(from: "(", to: ")")
        if (_s.0 != nil && _s.1!.count > 0) {
            nomore = false
            var sub2:String = String(_s.0!)
            var sub3:String = String(_s.1!)
            var sub4:String = String(_s.2!)
            final = "\(final)\(sub2)"
            if (sub3.contains("\n")){
                //print(sub3);
            }
            for i in sub3 {
                if (i == " " || i == "\n") {
                    //ok
                }else{
                    not = true
                    break
                }
            }
            if (!not){
                let t = "(\(sub3))"
                sub3 = t
                sub3 = sub3.replacingOccurrences(of: t, with: "")
            }
            final = "\(final)\(sub3)"
            sub1 = sub4
        }
        if (nomore) {
            final = "\(final)\(sub1)"
            _t = sub1.substring(from: "nvfh98237238453455%/%/&()YHUIGFV") //force-end
        }else{
            _t = sub1.substring(from: ")")
            if (_t.0 == nil || _t.1 == nil){
                final = "\(final)\(sub1)"
            }
        }
    }
    
    while (final.contains("if ()")) { final = final.replacingOccurrences(of: "if ()",  with: "if()") }
    while (final.contains("if()")) {
        final = final.replacingOccurrences(of: "if()",  with: "if (!_CE_) /*Piranhito?@*/ ")
    }
 
    /*
    if (final == tmp){
        print(final)
    }else{
        print(tmp)
    }
     */
    
    return final
    
}

func lineReformatter(_ progetto:String,_ source:String ) -> String {

    var r = source
    r = r.replacingOccurrences(of: "\n", with: " ")
    r = r.replacingOccurrences(of: "  ", with: " ")
    if (r.count > 5){
        print("trovato")
    }
    while (r.contains(":if(){") || r.contains(" if(){") || r.contains("if(){")) {
        break
        //r = r.replacingOccurrences(of: "if(){", with: " ")
    }
    
    return source
    
}

func linesHandler(_ progetto:String,_ line:String ) -> Bool {

    for prj in progetti {
        if (progetto == prj.id) {
            for l in prj.removableLines {
                if (line.contains(l.id)) {
                    return true
                }
            }
        }
    }
        
    return false
}

func returnTRUE () -> Bool { return true  }
func returnFALSE() -> Bool { return false }

func tokenRemover(_ progetto:String,_ line:String ) -> String {

    var tmp = line
    for prj in progetti {
        if (progetto == prj.id) {
            for l in prj.removableTokens {
                while (tmp.contains(l.id)) {
                    tmp = tmp.replacingOccurrences(of: l.id, with: "")
                }
            }
        }
    }
    
    return tmp
}

func tokenReplacer(_ progetto:String,_ line:String ) -> String {
    
    var baseline = line
    for prj in progetti {
        if (progetto == prj.id) {
            for twin in prj.replaceableTokens {
                baseline = baseline.replacingOccurrences(of: twin[0], with: twin[1])
            }
        }
    }
    
    return baseline

}

struct Line {
    var id:String
    var eyecatcher:String
}
struct Feature {
    var id:String
    var eyecatcher:String
}
struct Progetto {
    var id:String
    var replaceableStrings:[[String]]
    var availableFeatures:[Feature]
    var removableFeatures:[Feature]
    var removableLines:[Line]
    var removableTokens:[Line]
    var replaceableTokens:[[String]]
    var copyRightFeatures:[Feature]
    var copyRightStrings:[[String]]
}
let progetti = [Progetto(id: "Orientamento",
                                        replaceableStrings: [
                                            ["from","to"],
                                            ["from","to"],
                                            ["...","...."],
                                            ["public func contains(_ element: Element) -> Bool","public func include(_ element: Element) -> Bool"],
                                            ["guard contains(element)","guard include(element)"],
                                        /*  ["",""],
                                            ["",""],
                                            ["",""],
                                            ["",""],
                                            ["",""],
                                            ["",""],
                                            ["",""],
                                            ["",""], */],
                                        availableFeatures: [],
                                        removableFeatures: [Feature(id: "**", eyecatcher: "@anXjKh@"),
                                                            Feature(id: "*******", eyecatcher: "@7r7cgE@"),
                                                            Feature(id: "generic", eyecatcher: "@KRNgBy@"),
                                                            Feature(id: "Logger", eyecatcher: "@85Lbt3@"),
                                                            Feature(id: "Tracer", eyecatcher: "@O8gSAh@"),
                                                            Feature(id: "PostReviewer", eyecatcher: "@C58Dsg@"),
                                                            Feature(id: "PreSimulation", eyecatcher: "@FZXMf2@"),
                                                            Feature(id: "Sniffer", eyecatcher: "@iw9tXB@"),
                                                            Feature(id: "APBMRCM", eyecatcher: "@YjXXEH@"),
                                                            Feature(id: "FrzngCnf", eyecatcher: "@fpi5v0@"),
                                                            Feature(id: "KalmanFilter", eyecatcher: "@PTBBpC@"),
                                                            Feature(id: "ParticlesFilter", eyecatcher: "@Ggihzf@"),
                                                            Feature(id: "RollerReader", eyecatcher: "@TYv660@"),
                                                            Feature(id: "Crypto", eyecatcher: "@a03nxf@"),
                                                            Feature(id: "CacheLocal", eyecatcher: "@IqglzE@"),
                                                            Feature(id: "Router", eyecatcher: "@ENgIzB@"),
                                                            Feature(id: "Grapher", eyecatcher: "@4Fu5VH@"),
                                                            Feature(id: "jsNavigator", eyecatcher: "@Lz5WOQ@"),
                                                            Feature(id: "jsGrapher", eyecatcher: "@NgAmQD@")],
                                        
                                        removableLines: [Line(id: "/*Piranhito?@-#stmt-@GcDxPQ@*/", eyecatcher: ""),
                                                         Line(id: "Logger.log", eyecatcher: ""),
                                                         Line(id: "Logger.list", eyecatcher: ""),
                                                         Line(id: "Logger.rename", eyecatcher: ""),
                                                         Line(id: "Logger.retrieve", eyecatcher: ""),
                                                         Line(id: "Tracer.trace", eyecatcher: "")],
                                        removableTokens: [Line(id: "/*Piranhito?@-**-S@anXjKh@*/", eyecatcher: ""),
                                                          Line(id: "/*Piranhito?@-**-E@anXjKh@*/", eyecatcher: ""),
                                                          Line(id: "/*Piranhito?@-ptfgiakPreSimulation-S@FZXMf2@*/", eyecatcher: ""),
                                                          Line(id: "/*Piranhito?@-ptfgiakPreSimulation-E@FZXMf2@*/", eyecatcher: ""),
                                                          Line(id: "/*Piranhito?@-ptfgiakCacheLocal-S@IqglzE@*/", eyecatcher: ""),
                                                          Line(id: "/*Piranhito?@-ptfgiakCacheLocal-E@IqglzE@*/", eyecatcher: "")],
                                        replaceableTokens: [["/*Piranhito?@-","/*?@-"]/*,["print(","//("]*/],
                                        copyRightFeatures: [Feature(id: "123456", eyecatcher: "@654321@")],
                                        copyRightStrings: [["Created by xxx yyy","Created by xxx yyy zzz"],
                                            ["//  Copyright © 2020-2021 xxx yyy zzz. All rights reserved.\n",""],
                                            ["//  The name of xxx yyy zzz may not be used to endorse or promote\n//  products derived from this software without specific prior written permission.\n//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS \"AS IS\" AND\n//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED\n//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.\n//  IN NO EVENT SHALL xxx yyy zzz BE LIABLE FOR ANY DIRECT, INDIRECT,\n//  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES OR INJURIES (INCLUDING,\n//  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,\n//  OR PROFITS; OR BUSINESS INTERRUPTION; ACCIDENTS INVOLVING DEATH OR INJURIES TO THE\n//  PHYSICAL AND MENTAL INTEGRITY OF A PERSON; OR DATA PRIVACY AND PROTECTION ISSUES)\n//  HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,\n//  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS\n//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.\n",
                                             "//  The name of xxx yyy zzz may not be used to endorse or promote\n//  products derived from this software without specific prior written permission.\n/*******************************************************************************\n*\n* The MIT License (MIT)\n*\n* Copyright (c) 2020, 2021, 2022  xxx yyy zzz\n*\n* Permission is hereby granted, free of charge, to any person obtaining a copy\n* of this software and associated documentation files (the \"Software\"), to deal\n* in the Software without restriction, including without limitation the rights\n* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell\n* copies of the Software, and to permit persons to whom the Software is\n* furnished to do so, subject to the following conditions:\n*\n* The above copyright notice and this permission notice shall be included in\n* all copies or substantial portions of the Software.\n*\n* THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR\n* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,\n* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE\n* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER\n* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,\n* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN\n* THE SOFTWARE.\n*******************************************************************************/\n"]]
                                        ),
                Progetto(id: "SnifferUtil",
                                                        replaceableStrings: [
                                                            ["qwerty","qwertyUtil"],
                                                            ["salma","salmaUtil"]],
                                                        availableFeatures: [],
                                                        removableFeatures: [Feature(id: "**", eyecatcher: "@anXjKh@"),
                                                                            Feature(id: "*******", eyecatcher: "@7r7cgE@"),
                                                                            Feature(id: "generic", eyecatcher: "@KRNgBy@"),
                                                                            Feature(id: "Logger", eyecatcher: "@85Lbt3@"),
                                                                            Feature(id: "Tracer", eyecatcher: "@O8gSAh@"),
                                                                            Feature(id: "PostReviewer", eyecatcher: "@C58Dsg@"),
                                                                            Feature(id: "PreSimulation", eyecatcher: "@FZXMf2@"),
                                                                            //Feature(id: "Sniffer", eyecatcher: "@iw9tXB@"),
                                                                            Feature(id: "APBMRCM", eyecatcher: "@YjXXEH@"),
                                                                            Feature(id: "FrzngCnf", eyecatcher: "@fpi5v0@"),
                                                                            Feature(id: "KalmanFilter", eyecatcher: "@PTBBpC@"),
                                                                            Feature(id: "ParticlesFilter", eyecatcher: "@Ggihzf@"),
                                                                            Feature(id: "RollerReader", eyecatcher: "@TYv660@"),
                                                                            Feature(id: "Crypto", eyecatcher: "@a03nxf@"),
                                                                            Feature(id: "CacheLocal", eyecatcher: "@IqglzE@"),
                                                                            Feature(id: "Router", eyecatcher: "@ENgIzB@"),
                                                                            Feature(id: "Grapher", eyecatcher: "@4Fu5VH@"),
                                                                            Feature(id: "jsNavigator", eyecatcher: "@Lz5WOQ@"),
                                                                            Feature(id: "jsGrapher", eyecatcher: "@NgAmQD@")],
                                                        
                                                        removableLines: [Line(id: "/*Piranhito?@-#stmt-@GcDxPQ@*/", eyecatcher: ""),
                                                                         Line(id: "Logger.log", eyecatcher: ""),
                                                                         Line(id: "Logger.list", eyecatcher: ""),
                                                                         Line(id: "Logger.rename", eyecatcher: ""),
                                                                         Line(id: "Logger.retrieve", eyecatcher: ""),
                                                                         Line(id: "Tracer.trace", eyecatcher: "")],
                                                        removableTokens: [Line(id: "/*Piranhito?@-**-S@anXjKh@*/", eyecatcher: ""),
                                                                          Line(id: "/*Piranhito?@-**-E@anXjKh@*/", eyecatcher: ""),
                                                                          Line(id: "/*Piranhito?@-ptfgiakPreSimulation-S@FZXMf2@*/", eyecatcher: ""),
                                                                          Line(id: "/*Piranhito?@-ptfgiakPreSimulation-E@FZXMf2@*/", eyecatcher: ""),
                                                                          Line(id: "/*Piranhito?@-ptfgiakCacheLocal-S@IqglzE@*/", eyecatcher: ""),
                                                                          Line(id: "/*Piranhito?@-ptfgiakCacheLocal-E@IqglzE@*/", eyecatcher: "")],
                                                        replaceableTokens: [["/*Piranhito?@-","/*?@-"]/*,["print(","//("]*/],
                                                        copyRightFeatures: [Feature(id: "123456", eyecatcher: "@654321@")],
                                                        copyRightStrings: [["Created by xxx zzz","Created by xxx yyy zzz"],
                                                            ["Created by x. zzz","Created by xxx yyy zzz"],
                                                            ["Created by x.y. zzz","Created by xxx yyy zzz"],
                                                            ["Created by xxx y. zzz","Created by xxx yyy zzz"],
                                                            ["Created by xxx y zzz","Created by xxx yyy zzz"],
                                                            ["//  Copyright © 2020-2021 xxx yyy zzz. All rights reserved.\n","//  Copyright © 2020-2021 xxx yyy zzz. All rights reserved.\n//  The name of xxx yyy zzz may not be used to endorse or promote\n//  products derived from this software without specific prior written permission.\n//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS \"AS IS\" AND\n//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED\n//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.\n//  IN NO EVENT SHALL xxx yyy zzz BE LIABLE FOR ANY DIRECT, INDIRECT,\n//  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES OR INJURIES (INCLUDING,\n//  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,\n//  OR PROFITS; OR BUSINESS INTERRUPTION; ACCIDENTS INVOLVING DEATH OR INJURIES TO THE\n//  PHYSICAL AND MENTAL INTEGRITY OF A PERSON; OR DATA PRIVACY AND PROTECTION ISSUES)\n//  HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,\n//  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS\n//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.\n"]]
                                                        )]



// https://www.random.org/strings/?num=1&len=6&digits=on&upperalpha=on&loweralpha=on&unique=on&format=html&rnd=new

private var _trasformazione = false
private var _copyright = false
private var _progetto = ""
private var _directoryName = ""

    print("input parameters \(CommandLine.arguments.enumerated())")

    for (na,argument) in CommandLine.arguments.enumerated() {
        
        print("checking input parameter #\(na) > \(argument)")
        
        var arg:String = argument as String
        
        switch arg.lowercased() {
        case "-x".lowercased():
                //print("first argument \(arg)")
                _trasformazione = true

        case "-c".lowercased():
                //print("first argument \(arg)")
                _copyright = true

        case "Orientamento".lowercased():
                //print("second argument \(arg)")
                _progetto = arg
            
        case "SnifferUtil".lowercased():
                //print("second argument \(arg)")
                _progetto = arg
            
        default:
            if (na == 0){
                //print("base argument \(arg)")
            }else{
                if (na == 3) {
                    //print("third argument \(arg)")
                    _directoryName = arg
                }else{
                    if (na>0){
                        print("parametro #\(na) non riconosciuto \(argument)")
                    }else{
                        print("parametro #\(na) non valido \(argument)")
                    }
                    exit(3)
                    //EXIT_FAILURE
                }
            }
        }
        
        print("checked input parameter #\(na) > \(argument)")
        
    }

    
    if ((_trasformazione || _copyright) && _progetto != "" && _directoryName != "") {
        var validated = false
        for prj in progetti {
            if (prj.id == _progetto){
                validated = true
                break
            }
        }
        if validated {
            // ok
        }else{
            print("progetto inesistente \(_progetto)")
            print("progetti supportati \(progetti)")
            exit(2)
        }
        
    }else{
        print("parametri invalidi")
        exit(1)
    }

    if (_trasformazione){
        performTransformation(_progetto,_directoryName);
    }else{
        if (_copyright){
            performCopyrightAlignment(_progetto,_directoryName);
        }else{
            print("what?!")
            exit(4)
        }
    }

func performCopyrightAlignment(_ progetto:String, _ directoryName:String){
    
    var mods = 0

    var regex1 = try! NSRegularExpression(pattern: "[a-z].swift")

    let fm1 = FileManager.default
    let path1 = Bundle.main.resourcePath!

    do {
        let items = try fm1.contentsOfDirectory(atPath: directoryName)

        for item in items {
            if (regex1.matches(item.lowercased())) {
                print("\(getTOD()) processing file \(item)")
                //print("Found \(item)")
                 
                var path = "\(directoryName)\(item)"
                print(path)
                
                //reading
                var error:NSError?
                //reading
                let textReaded = try! String(contentsOfFile: path, encoding:.utf8)
                if let theError = error {
                    print("\(theError.localizedDescription)")
                }
                
                let textToAddAtTheTop = "" // it was "Inizio"
                do {
                      // Write contents to file
                      try (textToAddAtTheTop + "\n").write(toFile: path, atomically: false, encoding: String.Encoding.utf8)
                  }
                  catch let error as NSError {
                      print("An error took place: \(error)")
                  }
                
                let workInProgress0 = copyrightAligner(progetto,textReaded)
                
                let workInProgress1 = copyrightReplacer(progetto,workInProgress0)
                
                let righe = workInProgress1.split(separator: "\n")
                for riga in righe {
                    if (!linesHandler(progetto, String(riga))) {
                        let data2 = try! (riga + "\n").data(using: String.Encoding.utf8)
                        if let fileHandle2 = try? FileHandle(forWritingTo: URL(string: path)!) {
                                fileHandle2.seekToEndOfFile()
                                fileHandle2.write(data2!)
                            }else{
                            }
                    }
                }
                   
                let textToAddAtTheBotton = "" // it was fine
                let data3 = try! (textToAddAtTheBotton + "\n").data(using: String.Encoding.utf8)
                if let fileHandle3 = try? FileHandle(forWritingTo: URL(string: path)!) {
                        fileHandle3.seekToEndOfFile()
                        fileHandle3.write(data3!)
                        fileHandle3.closeFile()
                    }else{
                    }
                
                let chk = featuresChecker(progetto,textReaded)
                
                print("\(getTOD()) file \(item) processed")
                mods += 1

            }else{
                //print("\(getTOD()) file \(item) ignored")
            }
        }
    } catch {
        print(error)
        // failed to read directory – bad permissions, perhaps?
    }
    
    //

    regex1 = try! NSRegularExpression(pattern: "[a-z].js")

    do {
        let items = try fm1.contentsOfDirectory(atPath: directoryName)

        for item in items {
            if (regex1.matches(item.lowercased())) {
                print("\(getTOD()) processing file \(item)")
                //print("Found \(item)")
                 
                var path = "\(directoryName)\(item)"
                print(path)
                
                //reading
                var error:NSError?
                //reading
                let textReaded = try! String(contentsOfFile: path, encoding:.utf8)
                if let theError = error {
                    print("\(theError.localizedDescription)")
                }
                
                let textToAddAtTheTop = "" // it was "Inizio"
                do {
                      // Write contents to file
                      try (textToAddAtTheTop + "\n").write(toFile: path, atomically: false, encoding: String.Encoding.utf8)
                  }
                  catch let error as NSError {
                      print("An error took place: \(error)")
                  }
                
                let workInProgress0 = copyrightAligner(progetto,textReaded)
                
                let workInProgress1 = copyrightReplacer(progetto,workInProgress0)
                
                let righe = workInProgress1.split(separator: "\n")
                for riga in righe {
                    if (!linesHandler(progetto, String(riga))) {
                        let data2 = try! (riga + "\n").data(using: String.Encoding.utf8)
                        if let fileHandle2 = try? FileHandle(forWritingTo: URL(string: path)!) {
                                fileHandle2.seekToEndOfFile()
                                fileHandle2.write(data2!)
                            }else{
                            }
                    }
                }
                   
                let textToAddAtTheBotton = "" // it was fine
                let data3 = try! (textToAddAtTheBotton + "\n").data(using: String.Encoding.utf8)
                if let fileHandle3 = try? FileHandle(forWritingTo: URL(string: path)!) {
                        fileHandle3.seekToEndOfFile()
                        fileHandle3.write(data3!)
                        fileHandle3.closeFile()
                    }else{
                    }
                
                let chk = featuresChecker(progetto,textReaded)
                
                print("\(getTOD()) file \(item) processed")
                mods += 1

            }else{
                //print("\(getTOD()) file \(item) ignored")
            }
        }
    } catch {
        print(error)
        // failed to read directory – bad permissions, perhaps?
    }
    
    //

    regex1 = try! NSRegularExpression(pattern: "[a-z].json")

    do {
        let items = try fm1.contentsOfDirectory(atPath: directoryName)

        for item in items {
            if (regex1.matches(item.lowercased())) {
                print("\(getTOD()) processing file \(item)")
                //print("Found \(item)")
                 
                var path = "\(directoryName)\(item)"
                print(path)
                
                //reading
                var error:NSError?
                //reading
                let textReaded = try! String(contentsOfFile: path, encoding:.utf8)
                if let theError = error {
                    print("\(theError.localizedDescription)")
                }
                
                let textToAddAtTheTop = "" // it was "Inizio"
                do {
                      // Write contents to file
                      try (textToAddAtTheTop + "\n").write(toFile: path, atomically: false, encoding: String.Encoding.utf8)
                  }
                  catch let error as NSError {
                      print("An error took place: \(error)")
                  }
                
                let workInProgress0 = copyrightAligner(progetto,textReaded)
                
                let workInProgress1 = copyrightReplacer(progetto,workInProgress0)
                
                let righe = workInProgress1.split(separator: "\n")
                for riga in righe {
                    if (!linesHandler(progetto, String(riga))) {
                        let data2 = try! (riga + "\n").data(using: String.Encoding.utf8)
                        if let fileHandle2 = try? FileHandle(forWritingTo: URL(string: path)!) {
                                fileHandle2.seekToEndOfFile()
                                fileHandle2.write(data2!)
                            }else{
                            }
                    }
                }
                   
                let textToAddAtTheBotton = "" // it was fine
                let data3 = try! (textToAddAtTheBotton + "\n").data(using: String.Encoding.utf8)
                if let fileHandle3 = try? FileHandle(forWritingTo: URL(string: path)!) {
                        fileHandle3.seekToEndOfFile()
                        fileHandle3.write(data3!)
                        fileHandle3.closeFile()
                    }else{
                    }
                
                let chk = featuresChecker(progetto,textReaded)
                
                print("\(getTOD()) file \(item) processed")
                mods += 1

            }else{
                //print("\(getTOD()) file \(item) ignored")
            }
        }
    } catch {
        print(error)
        // failed to read directory – bad permissions, perhaps?
    }

    //

    regex1 = try! NSRegularExpression(pattern: "[a-z].strings")

    do {
        let items = try fm1.contentsOfDirectory(atPath: directoryName)

        for item in items {
            if (regex1.matches(item.lowercased())) {
                print("\(getTOD()) processing file \(item)")
                //print("Found \(item)")
                 
                var path = "\(directoryName)\(item)"
                print(path)
                
                //reading
                var error:NSError?
                //reading
                let textReaded = try! String(contentsOfFile: path, encoding:.utf8)
                if let theError = error {
                    print("\(theError.localizedDescription)")
                }
                
                let textToAddAtTheTop = "" // it was "Inizio"
                do {
                      // Write contents to file
                      try (textToAddAtTheTop + "\n").write(toFile: path, atomically: false, encoding: String.Encoding.utf8)
                  }
                  catch let error as NSError {
                      print("An error took place: \(error)")
                  }
                
                let workInProgress0 = copyrightAligner(progetto,textReaded)
                
                let workInProgress1 = copyrightReplacer(progetto,workInProgress0)
                
                let righe = workInProgress1.split(separator: "\n")
                for riga in righe {
                    if (!linesHandler(progetto, String(riga))) {
                        let data2 = try! (riga + "\n").data(using: String.Encoding.utf8)
                        if let fileHandle2 = try? FileHandle(forWritingTo: URL(string: path)!) {
                                fileHandle2.seekToEndOfFile()
                                fileHandle2.write(data2!)
                            }else{
                            }
                    }
                }
                   
                let textToAddAtTheBotton = "" // it was fine
                let data3 = try! (textToAddAtTheBotton + "\n").data(using: String.Encoding.utf8)
                if let fileHandle3 = try? FileHandle(forWritingTo: URL(string: path)!) {
                        fileHandle3.seekToEndOfFile()
                        fileHandle3.write(data3!)
                        fileHandle3.closeFile()
                    }else{
                    }
                
                let chk = featuresChecker(progetto,textReaded)
                
                print("\(getTOD()) file \(item) processed")
                mods += 1

            }else{
                //print("\(getTOD()) file \(item) ignored")
            }
        }
    } catch {
        print(error)
        // failed to read directory – bad permissions, perhaps?
    }


    print("CopyRight Alignment Done \(mods)")
    
}

func performTransformation(_ progetto:String, _ directoryName:String){
    
    var mods = 0

    // SWIFT CODE
    
    let _regex1 = try! NSRegularExpression(pattern: ".*/[^.~]*\\.swift$")
    let regex1 = try! NSRegularExpression(pattern: "[a-z].swift")

    let fm1 = FileManager.default
    let path1 = Bundle.main.resourcePath!

    // PRIMA

    do {
        let items = try fm1.contentsOfDirectory(atPath: directoryName)

        for item in items {
            if (regex1.matches(item.lowercased())) {
                print("\(getTOD()) processing file \(item)")
                //print("Found \(item)")
                 
                var path = "\(directoryName)\(item)"
                print(path)
                
                //reading
                var error:NSError?
                //reading
                let textReaded = try! String(contentsOfFile: path, encoding:.utf8)
                if let theError = error {
                    print("\(theError.localizedDescription)")
                }
                
                let textToAddAtTheTop = "" // it was "Inizio"
                do {
                      // Write contents to file
                      try (textToAddAtTheTop + "\n").write(toFile: path, atomically: false, encoding: String.Encoding.utf8)
                  }
                  catch let error as NSError {
                      print("An error took place: \(error)")
                  }
                
                let workInProgress0 = featuresRemover(progetto,textReaded)
                
                let workInProgress1 = stringReplacer(progetto,workInProgress0)
                
                let workInProgress2 = reformatter(progetto,workInProgress1)
                
                let righe = workInProgress2.split(separator: "\n")
                for riga in righe {
                    if (!linesHandler(progetto, String(riga))) {
                        let data2 = try! (riga + "\n").data(using: String.Encoding.utf8)
                        if let fileHandle2 = try? FileHandle(forWritingTo: URL(string: path)!) {
                                fileHandle2.seekToEndOfFile()
                                fileHandle2.write(data2!)
                            }else{
                            }
                    }
                }
                   
                let textToAddAtTheBotton = "" // it was fine
                let data3 = try! (textToAddAtTheBotton + "\n").data(using: String.Encoding.utf8)
                if let fileHandle3 = try? FileHandle(forWritingTo: URL(string: path)!) {
                        fileHandle3.seekToEndOfFile()
                        fileHandle3.write(data3!)
                        fileHandle3.closeFile()
                    }else{
                    }
                
                let chk = featuresChecker(progetto,textReaded)
                
                print("\(getTOD()) file \(item) processed")
                mods += 1

            }else{
                //print("\(getTOD()) file \(item) ignored")
            }
        }
    } catch {
        print(error)
        // failed to read directory – bad permissions, perhaps?
    }

    // DOPO

    do {
        let items = try fm1.contentsOfDirectory(atPath: directoryName)

        for item in items {
            if (regex1.matches(item.lowercased())) {
                print("\(getTOD()) processing file \(item)")
                //print("Found \(item)")
                 
                var path = "\(directoryName)\(item)"
            
                //reading
                var error:NSError?
                //reading
                let textReaded = try! String(contentsOfFile: path, encoding:.utf8)
                if let theError = error {
                    print("\(theError.localizedDescription)")
                }
                
                let textToAddAtTheTop = "" // it was "Inizio"
                do {
                      // Write contents to file
                      try (textToAddAtTheTop + "\n").write(toFile: path, atomically: false, encoding: String.Encoding.utf8)
                  }
                  catch let error as NSError {
                      print("An error took place: \(error)")
                  }
                
                let workInProgress0 = makeItBeauty(progetto,textReaded)
                
                let righe = workInProgress0.split(separator: "\n")
                for riga in righe {
                    if (returnTRUE()) {
                        var tmp = tokenRemover(progetto,String(riga))
                        tmp = tokenReplacer(progetto,String(tmp))
                        let data2 = try! (tmp + "\n").data(using: String.Encoding.utf8)
                        if let fileHandle2 = try? FileHandle(forWritingTo: URL(string: path)!) {
                                fileHandle2.seekToEndOfFile()
                                fileHandle2.write(data2!)
                            }else{
                            }
                    }
                }
                   
                let textToAddAtTheBotton = "" // it was fine
                let data3 = try! (textToAddAtTheBotton + "\n").data(using: String.Encoding.utf8)
                if let fileHandle3 = try? FileHandle(forWritingTo: URL(string: path)!) {
                        fileHandle3.seekToEndOfFile()
                        fileHandle3.write(data3!)
                        fileHandle3.closeFile()
                    }else{
                    }
                
                let chk = featuresChecker(progetto,textReaded)
                
                print("\(getTOD()) file \(item) processed")
                mods += 1

            }else{
                //print("\(getTOD()) file \(item) ignored")
            }
        }
    } catch {
        print(error)
        // failed to read directory – bad permissions, perhaps?
    }

    // JS CODE

    let _regex2 = try! NSRegularExpression(pattern: ".*/[^.~]*\\.js$")
    let regex2 = try! NSRegularExpression(pattern: "[a-z].js")

    let fm2 = FileManager.default
    let path2 = Bundle.main.resourcePath!

    // PRIMA

    do {
        let items = try fm2.contentsOfDirectory(atPath: directoryName)

        for item in items {
            if (regex2.matches(item.lowercased())) {
                print("\(getTOD()) processing file \(item)")
                //print("Found \(item)")
                 
                var path = "\(directoryName)\(item)"
            
                //reading
                var error:NSError?
                //reading
                let textReaded = try! String(contentsOfFile: path, encoding:.utf8)
                if let theError = error {
                    print("\(theError.localizedDescription)")
                }
                
                // PRIMA
                
                let textToAddAtTheTop = "" // it was "Inizio"
                do {
                      // Write contents to file
                      try (textToAddAtTheTop + "\n").write(toFile: path, atomically: false, encoding: String.Encoding.utf8)
                  }
                  catch let error as NSError {
                      print("An error took place: \(error)")
                  }
                
                let workInProgress0 = featuresRemover(progetto,textReaded)
                
                let workInProgress1 = stringReplacer(progetto,workInProgress0)
                
                let workInProgress2 = reformatter(progetto,workInProgress1)
                
                let righe = workInProgress2.split(separator: "\n")
                for riga in righe {
                    if (!linesHandler(progetto, String(riga))) {
                        let data2 = try! (riga + "\n").data(using: String.Encoding.utf8)
                        if let fileHandle2 = try? FileHandle(forWritingTo: URL(string: path)!) {
                                fileHandle2.seekToEndOfFile()
                                fileHandle2.write(data2!)
                            }else{
                            }
                    }
                }
                   
                let textToAddAtTheBotton = "" // it was fine
                let data3 = try! (textToAddAtTheBotton + "\n").data(using: String.Encoding.utf8)
                if let fileHandle3 = try? FileHandle(forWritingTo: URL(string: path)!) {
                        fileHandle3.seekToEndOfFile()
                        fileHandle3.write(data3!)
                        fileHandle3.closeFile()
                    }else{
                    }
                
                let chk = featuresChecker(progetto,textReaded)
                
                print("\(getTOD()) file \(item) processed")
                mods += 1
                
            }else{
                //print("\(getTOD()) file \(item) ignored")
            }
        }
    } catch {
        print(error)
        // failed to read directory – bad permissions, perhaps?
    }

    // DOPO

    do {
        let items = try fm2.contentsOfDirectory(atPath: directoryName)

        for item in items {
            if (regex2.matches(item.lowercased())) {
                print("\(getTOD()) processing file \(item)")
                //print("Found \(item)")
                 
                var path = "\(directoryName)\(item)"
            
                //reading
                var error:NSError?
                //reading
                let textReaded = try! String(contentsOfFile: path, encoding:.utf8)
                if let theError = error {
                    print("\(theError.localizedDescription)")
                }
                
                // PRIMA
                
                let textToAddAtTheTop = "" // it was "Inizio"
                do {
                      // Write contents to file
                      try (textToAddAtTheTop + "\n").write(toFile: path, atomically: false, encoding: String.Encoding.utf8)
                  }
                  catch let error as NSError {
                      print("An error took place: \(error)")
                  }
                
                let workInProgress0 = makeItBeauty(progetto,textReaded)
                
                let righe = workInProgress0.split(separator: "\n")
                for riga in righe {
                    if (returnTRUE()) {
                        var tmp = tokenRemover(progetto,String(riga))
                        tmp = tokenReplacer(progetto,String(tmp))
                        let data2 = try! (tmp + "\n").data(using: String.Encoding.utf8)
                        if let fileHandle2 = try? FileHandle(forWritingTo: URL(string: path)!) {
                                fileHandle2.seekToEndOfFile()
                                fileHandle2.write(data2!)
                            }else{
                            }
                    }
                }
                   
                let textToAddAtTheBotton = "" // it was fine
                let data3 = try! (textToAddAtTheBotton + "\n").data(using: String.Encoding.utf8)
                if let fileHandle3 = try? FileHandle(forWritingTo: URL(string: path)!) {
                        fileHandle3.seekToEndOfFile()
                        fileHandle3.write(data3!)
                        fileHandle3.closeFile()
                    }else{
                    }
                
                let chk = featuresChecker(progetto,textReaded)
                
                print("\(getTOD()) file \(item) processed")
                mods += 1
                
            }else{
                //print("\(getTOD()) file \(item) ignored")
            }
        }
    } catch {
        print(error)
        // failed to read directory – bad permissions, perhaps?
    }

    print("Transformation Done \(mods)")
    
}


exit(0)

let piranhito = Piranhito()
if CommandLine.argc < 2 {
    piranhito.interactiveMode()
} else {
    piranhito.staticMode()
}

