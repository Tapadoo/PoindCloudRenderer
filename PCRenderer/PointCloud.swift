//
//  PointCloud.swift
//  MixedReality
//
//  Created by Evgeniy Upenik on 21.05.17.
//  Copyright © 2017 Evgeniy Upenik. All rights reserved.
//

import SceneKit

@objc class PointCloud: NSObject {
    
    var n : Int = 0
    var pointCloud : Array<SCNVector3> = []
    
    init(filename: String = "bun_zipper_points") {
        super.init()
        
        self.n = 0
        var x, y, z : Double
        (x,y,z) = (0,0,0)
        
        // Open file
        if let path = Bundle.main.path(forResource: filename, ofType: "ply") {
            do {
                let data = try String(contentsOfFile: path, encoding: .ascii)
                var myStrings = data.components(separatedBy: "\n")
                
                // Read header
                while !myStrings.isEmpty {
                    let line = myStrings.removeFirst()
                    if line.hasPrefix("element vertex ") {
                        n = Int(line.components(separatedBy: " ")[2])!
                        continue
                    }
                    if line.hasPrefix("end_header") {
                        break
                    }
                }
                
                pointCloud = Array<SCNVector3>(repeating: SCNVector3(x:0,y:0,z:0), count: n)
                
                // Read data
                for i in 0...(self.n-1) {
                    let line = myStrings[i]
                    x = Double(line.components(separatedBy: " ")[0])!
                    y = Double(line.components(separatedBy: " ")[1])!
                    z = Double(line.components(separatedBy: " ")[2])!
                    
                    pointCloud[i].x = Float(x)
                    pointCloud[i].y = Float(y)
                    pointCloud[i].z = Float(z)
                }
                NSLog("Point cloud data loaded: %d points",n)
            } catch {
                print(error)
            }
        }
        
    }
    
    
    public func getNode() -> SCNNode {
        
        let vertices = self.pointCloud.map { point in
            return PointCloudVertex(x: point.x,y: point.y,z: point.z,r: 1,g: 1,b: 1)
        }
        
        let node = buildNode(points: vertices)
        NSLog(String(describing: node))
        return node
    }
    
    private func buildNode(points: [PointCloudVertex]) -> SCNNode {
        let vertexData = NSData(
            bytes: points,
            length: MemoryLayout<PointCloudVertex>.size * points.count
        )
        let positionSource = SCNGeometrySource(
            data: vertexData as Data,
            semantic: SCNGeometrySource.Semantic.vertex,
            vectorCount: points.count,
            usesFloatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: MemoryLayout<Float>.size,
            dataOffset: 0,
            dataStride: MemoryLayout<PointCloudVertex>.size
        )
        let colorSource = SCNGeometrySource(
            data: vertexData as Data,
            semantic: SCNGeometrySource.Semantic.color,
            vectorCount: points.count,
            usesFloatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: MemoryLayout<Float>.size,
            dataOffset: MemoryLayout<Float>.size * 3,
            dataStride: MemoryLayout<PointCloudVertex>.size
        )
        let elements = SCNGeometryElement(
            data: nil,
            primitiveType: .point,
            primitiveCount: points.count,
            bytesPerIndex: MemoryLayout<Int>.size
        )
        elements.pointSize = 1
        elements.minimumPointScreenSpaceRadius = 1
        elements.maximumPointScreenSpaceRadius = 1
        
        let pointsGeometry = SCNGeometry(sources: [positionSource, colorSource], elements: [elements])
        let material = SCNMaterial()
        material.specular.contents = UIColor.white
        material.lightingModel = .constant
        pointsGeometry.materials = [material]
        
        return SCNNode(geometry: pointsGeometry)
    }
}
