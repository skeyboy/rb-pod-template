#!/usr/bin/env xcrun swift
import Cocoa

func shell(_ args: [String]) -> String {
    let task = Process()
    task.launchPath = "/usr/bin/env"
    task.arguments = args
    let pipe = Pipe()
    task.standardOutput = pipe
    task.launch()
    task.waitUntilExit()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output: String = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
    return output;
}

extension  String  {
     
     //使用正则表达式替换
     func  pregReplace(pattern:  String , with:  String ,
                      options:  NSRegularExpression . Options  = []) ->  String?  {
         do {
             let  regex = try  NSRegularExpression (pattern: pattern, options: options)
             return  regex.stringByReplacingMatches( in :  self , options: [],
                                                   range:  NSMakeRange (0,  self .count),
                                                   withTemplate: with)
         } catch {
             print(error)
         }
        return nil
     }
    
    func regexPattern(pattern:String, template: String) -> String {
            
            var finalStr = self
            do {
              
                // - 1、创建规则
                let pattern = pattern
                // - 2、创建正则表达式对象
                let regex = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive)
                
                // - 3、正则替换
                finalStr = regex.stringByReplacingMatches(in: self, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, self.count), withTemplate: template)
                
    //            获取满足条件的集合
//                let res = regex.matches(in: str, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, content.count))
//                print(res)
                
            }
            catch {
                print(error)
            }
            
            return finalStr
         
        }
}

print(CommandLine.arguments)
let podFilePath = CommandLine.arguments[1]
let podName = CommandLine.arguments[2]
let commitId = CommandLine.arguments[3]
let isGitSource = CommandLine.arguments[4]


let pod = try! String(contentsOfFile: "\(podFilePath)")

print(pod)
let pattern = "s.source.*:(git||http).*"
let binaryHttpUrl = "https://github.com/skeyboy/\(podName)/\(commitId).zip"
let binnarySourceTemplate = """
s.source           = { :http => '\(binaryHttpUrl)' }
"""

let gitSourceTemplate =  """
s.source           = { :git => 'https://github.com/skeyboy/\(podName).git', :tag => s.version.to_s }
"""
if isGitSource == "1" {
    
   let rev = pod.regexPattern(pattern: pattern, template:gitSourceTemplate)
    //print(rev)
    try! rev.write(toFile: podFilePath, atomically: true, encoding: String.Encoding.utf8)
} else {
    
    let rev = pod.regexPattern(pattern: pattern, template:binnarySourceTemplate)
    try! rev.write(toFile: podFilePath, atomically: true, encoding: String.Encoding.utf8)
}

