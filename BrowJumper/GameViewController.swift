//
//  GameViewController.swift
//  FaceRun
//
//  Created by Brian Advent on 21.06.18.
//  Copyright © 2018 Brian Advent. All rights reserved.
//

import UIKit
import SpriteKit
import ARKit

class GameViewController: UIViewController, ARSessionDelegate {

    var gameScene:GameScene!
    var session:ARSession!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let scene = MenuScene(fileNamed:"MenuScene")
        let skView = view as! SKView
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.ignoresSiblingOrder = false
        //print (view.bounds.size)
        //scene?.size = CGSize(width: 414, height: 896)
        scene?.scaleMode = .fill
        skView.presentScene(scene)            
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)    
    }
    
    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
