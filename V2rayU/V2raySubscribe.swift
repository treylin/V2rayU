//
//  V2raySubscribe.swift
//  V2rayU
//
//  Created by yanue on 2019/5/15.
//  Copyright © 2019 yanue. All rights reserved.
//

import Cocoa
import SwiftyJSON

// ----- v2ray subscribe manager -----
class V2raySubscribe: NSObject {
    static var shared = V2raySubscribe()

    // Initialization
    override init() {
        super.init()
        print("V2raySubscribe init")
        V2raySubscribe.loadConfig()
    }

    // v2ray subscribe list
    static private var v2raySubList: [V2raySubItem] = []

    // (init) load v2ray subscribe list from UserDefaults
    static func loadConfig() {
        // static reset
        self.v2raySubList = []

        // load name list from UserDefaults
        let list = UserDefaults.getArray(forKey: .v2raySubList)
        print("loadConfig", list!)

        if list == nil {
            return
        }
        // load each V2raySubItem
        for item in list! {
            guard let v2ray = V2raySubItem.load(name: item) else {
                // delete from UserDefaults
                V2raySubItem.remove(name: item)
                continue
            }
            // append
            self.v2raySubList.append(v2ray)
        }
    }

    // get list from v2ray subscribe list
    static func list() -> [V2raySubItem] {
        return self.v2raySubList
    }

    // get count from v2ray subscribe list
    static func count() -> Int {
        return self.v2raySubList.count
    }

    static func edit(rowIndex: Int, remark: String) {
        if !self.v2raySubList.indices.contains(rowIndex) {
            NSLog("index out of range", rowIndex)
            return
        }

        // update list
        self.v2raySubList[rowIndex].remark = remark

        // save
        let v2ray = self.v2raySubList[rowIndex]
        v2ray.remark = remark
        v2ray.store()
    }

    static func edit(rowIndex: Int, url: String) {
        if !self.v2raySubList.indices.contains(rowIndex) {
            NSLog("index out of range", rowIndex)
            return
        }

        // update list
        self.v2raySubList[rowIndex].url = url

        // save
        let v2ray = self.v2raySubList[rowIndex]
        v2ray.url = url
        v2ray.store()
    }

    // move item to new index
    static func move(oldIndex: Int, newIndex: Int) {
        if !V2raySubscribe.v2raySubList.indices.contains(oldIndex) {
            NSLog("index out of range", oldIndex)
            return
        }
        if !V2raySubscribe.v2raySubList.indices.contains(newIndex) {
            NSLog("index out of range", newIndex)
            return
        }

        let o = self.v2raySubList[oldIndex]
        self.v2raySubList.remove(at: oldIndex)
        self.v2raySubList.insert(o, at: newIndex)

        // update subscribe list UserDefaults
        self.saveItemList()
    }

    // add v2ray subscribe (by scan qrcode)
    static func add(remark: String, url: String) {
        if self.v2raySubList.count > 50 {
//            NSLog("over max len")
//            return
        }

        // name is : subscribe. + uuid
        let name = "subscribe." + UUID().uuidString

        let v2ray = V2raySubItem(name: name, remark: remark, url: url)
        // save to v2ray UserDefaults
        v2ray.store()

        // just add to mem
        self.v2raySubList.append(v2ray)

        // update subscribe list UserDefaults
        self.saveItemList()
    }

    // remove v2ray subscribe (tmp and UserDefaults and config json file)
    static func remove(idx: Int) {
        if !V2raySubscribe.v2raySubList.indices.contains(idx) {
            NSLog("index out of range", idx)
            return
        }

        let v2ray = V2raySubscribe.v2raySubList[idx]

        // delete from tmp
        self.v2raySubList.remove(at: idx)

        // delete from v2ray UserDefaults
        V2raySubItem.remove(name: v2ray.name)

        // update subscribe list UserDefaults
        self.saveItemList()
    }

    // update subscribe list UserDefaults
    static private func saveItemList() {
        var v2raySubList: Array<String> = []
        for item in V2raySubscribe.list() {
            v2raySubList.append(item.name)
        }

        UserDefaults.setArray(forKey: .v2raySubList, value: v2raySubList)
    }

    // load json file data
    static func loadSubItem(idx: Int) -> V2raySubItem? {
        if !V2raySubscribe.v2raySubList.indices.contains(idx) {
            NSLog("index out of range", idx)
            return nil
        }

        return self.v2raySubList[idx]
    }
}

// ----- v2ray subscribe item -----
class V2raySubItem: NSObject, NSCoding {
    var name: String
    var remark: String
    var isValid: Bool
    var url: String

    // init
    required init(name: String, remark: String, url: String, isValid: Bool = true) {
        self.name = name
        self.remark = remark
        self.isValid = isValid
        self.url = url
    }

    // decode
    required init(coder decoder: NSCoder) {
        self.name = decoder.decodeObject(forKey: "Name") as? String ?? ""
        self.remark = decoder.decodeObject(forKey: "Remark") as? String ?? ""
        self.isValid = decoder.decodeBool(forKey: "IsValid")
        self.url = decoder.decodeObject(forKey: "Url") as? String ?? ""
    }

    // object encode
    func encode(with coder: NSCoder) {
        coder.encode(name, forKey: "Name")
        coder.encode(remark, forKey: "Remark")
        coder.encode(isValid, forKey: "IsValid")
        coder.encode(url, forKey: "Url")
    }

    // store into UserDefaults
    func store() {
        let modelData = NSKeyedArchiver.archivedData(withRootObject: self)
        UserDefaults.standard.set(modelData, forKey: self.name)
    }

    // static load from UserDefaults
    static func load(name: String) -> V2raySubItem? {
        guard let myModelData = UserDefaults.standard.data(forKey: name) else {
            return nil
        }
        do {
            let result = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(myModelData)
            return result as? V2raySubItem
        } catch {
            print("load userDefault error:", error)
            return nil
        }
    }

    // remove from UserDefaults
    static func remove(name: String) {
        UserDefaults.standard.removeObject(forKey: name)
    }
}
