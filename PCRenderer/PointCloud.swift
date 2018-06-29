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
        
        // Open file
        if let path = Bundle.main.path(forResource: filename, ofType: "ply") {
            do {
                let data = try String(contentsOfFile: path, encoding: .ascii)
                NSLog("Point cloud loaded from file")
                
                //Without a header, we dont know our point count
                guard let headerEndRange = data.range(of: "end_header") else {return }
                
                //We need to extract the point count from the header. Lets get the header as a substring to work with
                let headerSubString = data[data.startIndex ... headerEndRange.upperBound]
                
                
                guard let elementVertexRange = headerSubString.range(of: "element vertex ") else {return }
                
                //This is the substring container the number followed by the rest of the header
                let vertexCountParialString = headerSubString.suffix(from: elementVertexRange.upperBound)
                
                //Find the next line break and create a substring with just the vertex count
                let vertexEndIndex = vertexCountParialString.index(of: "\n") ?? vertexCountParialString.endIndex
                let vertexCountString = vertexCountParialString[..<vertexEndIndex]
                
                n = Int(vertexCountString) ?? 0
                
                NSLog("Header parsed")
                
                pointCloud.reserveCapacity(n)
                
                var x: Float = 0
                var y: Float = 0
                var z: Float = 0
                
                let pointStartIndex = headerEndRange.upperBound
                
                let pointDataSubString = data[pointStartIndex...]

                let dataScanner = Scanner(string: String(pointDataSubString))
                
                // Read data
                for _ in 0 ..< n {

                    dataScanner.scanFloat(&x)
                    dataScanner.scanFloat(&y)
                    dataScanner.scanFloat(&z)
                    
                    //bunny model for example has extra points. lets ignore anything but the first 3 floats for now
                    dataScanner.scanUpToCharacters(from: CharacterSet.newlines, into: nil)
                    
                    let vector = SCNVector3(x: x , y: y, z: z)
                    pointCloud.append(vector)
                }
                NSLog("Point cloud data loaded: %d points", n)
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
