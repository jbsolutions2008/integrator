//
//  File.swift
//  
//
//  Created by Ganesh Faterpekar on 2/12/21.
//

import Foundation
import ArgumentParser

struct InstallSDK: ParsableCommand {
    static var configuration: CommandConfiguration {
        .init(
          commandName: "install",
          abstract: "Install the SDK"
        )
    }
    
    @Argument(help: "Yaml Config path")
    var configYmlPath: String
    
    func run() throws {
        try install_contextual_sdk(configFilePath: configYmlPath)

    }
    
    func install_contextual_sdk(configFilePath: String) throws {
        let configYmlData = try? read_file(filePath: configFilePath)
        var configYml = ConfigDetails()
        
        if let ymlData = configYmlData {
            guard let result = try? decodeConfigYML(ymlString: ymlData)?.integrator else {
                return
            }
            
            configYml = result
        }
    
        go_to_project_folder(path: configYml.path)
        
        if(configYml.git != "" ) {
           gitClone(url:configYml.git)
        }
       
        var finalPath = "\(configYml.path)/\(configYml.name)"
        
        if (!check_If_file_exists_at(fileName: finalPath + "/" + configYml.name + ".xcodeproj")) {
           let tempPath = "\(configYml.path)/\(configYml.name.lowercased())"
           if(check_If_file_exists_at(fileName: tempPath + "/" + configYml.name + ".xcodeproj")) {
               finalPath = tempPath
           } else {
                 print("Project Name doesn't exsists")
                 return ;
              }
        }
        
        
        go_to_project_folder(path: finalPath)
        copy_xcode_helper_script()
        
        performPodsPreCheck(projectName: configYml.name)
        try addPodSteps()
        
        try addBridgingHeaders(projectName: configYml.name, projectPath: configYml.path)
        
        go_to_project_folder(path: finalPath+"/"+configYml.name)
        try performSwiftIntegraton(projectName: configYml.name, appkey: configYml.key ,controllers: configYml.controller)
        
        go_to_project_folder(path: finalPath)
        replace_bases_classes (projetName: configYml.name,controllers: configYml.controller)
        
        openXcodeProject(path: finalPath ,name: configYml.name)
        
    }
    
    
    func performPodsPreCheck(projectName: String) {

        if check_If_file_exists_at(fileName: projectName) &&
           !check_If_file_exists_at(fileName: "Podfile") {
            create_pod_file()
        }
    }
    
    func addPodSteps() throws {
        try add_pointzi_to_pod()
        pod_install()
    }
    
    func createTemporaryGitRepo() {
        gitInit()
    }
   
    func performSwiftIntegraton(projectName: String , appkey: String , controllers:[String]) throws {
        do {
            try add_Intializer_In_AppDelegate (projectName : projectName, app_key: appkey)
        } catch {
                print(error)
        }
    }
}

func addBridgingHeaders(projectName: String ,projectPath: String) throws {
    try create_bridging_header_file(projectName: projectName)
    add_headers_to_xcode_settings(projectPath: projectPath, projectName: projectName)
}

func openXcodeProject(path: String, name: String) {
    print("Opening xcode project")
    go_to_project_folder(path: path)
    _  = shell(command: "open \(path)/\(name).xcworkspace")
}