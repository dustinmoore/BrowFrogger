//
//  MenuScene.swift
//  Brow Jumper
//
//  Created by Dustin Moore on 1/17/20.
//  Copyright © 2020 Brian Advent. All rights reserved.
//

import SpriteKit
import GameKit
import GameplayKit
import AVFoundation

class MenuScene: SKScene {
    
    private var playerNode:Player?
    var topRoad: SKSpriteNode!
    var bottomRoad: SKSpriteNode!
    var moving:Bool = false
    
    var generator:UIImpactFeedbackGenerator!
        
    var gameTimer: Timer!
    
    var possibleLeftCars = ["left-car-1", "left-car-2", "left-car-3", "left-car-4"]
    var possibleRightCars = ["right-car-1", "right-car-2", "right-car-3", "right-car-4"]
        
    override func didMove(to view: SKView) {
        
        setupPhysics()
        setupRoads()
        addLabels()
        
        generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        
        addCar()
        
        gameTimer = Timer.scheduledTimer(timeInterval: 3.75, target: self, selector: #selector(addCar), userInfo: nil, repeats: true)
    }
    
    func addLabels() {
        let playLabel = SKLabelNode(text: "Tap to Play!")
        playLabel.fontName = "AvenirNext-Bold"
        playLabel.fontSize = 50.0
        playLabel.fontColor = UIColor.white
        playLabel.position = CGPoint(x: frame.midX, y: frame.midY)
        playLabel.zPosition = 1
        addChild(playLabel)
        animate(label: playLabel)
        
        let instructionLabel = SKLabelNode(text: "Move the frog with your eyebrows!")
        instructionLabel.fontName = "AvenirNext-Bold"
        instructionLabel.fontSize = 18.0
        instructionLabel.fontColor = UIColor.white
        instructionLabel.position = CGPoint(x: frame.midX, y: frame.midY - 30)
        instructionLabel.zPosition = 1
        addChild(instructionLabel)
    }
    
    func animate(label: SKLabelNode) {
        // let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        // let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        
        let scaleUp = SKAction.scale(to: 1.1, duration: 0.5)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.5)
        
        let sequence = SKAction.sequence([scaleUp, scaleDown])
        label.run(SKAction.repeatForever(sequence))
    }
    
    func setupRoads() {
        topRoad = self.childNode(withName: "topRoad") as? SKSpriteNode
        bottomRoad = self.childNode(withName: "bottomRoad") as? SKSpriteNode
    }
    
    @objc func addCar () {
        possibleLeftCars = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: possibleLeftCars) as! [String]
        
        let leftCar = SKSpriteNode(imageNamed: possibleLeftCars[0])
        leftCar.position = CGPoint(x: frame.maxX + 60, y: topRoad.position.y)
        leftCar.zPosition = 1
        leftCar.setScale(0.75)
        leftCar.name = "car"
        
        self.addChild(leftCar)
        
        let animationDuration = 6
        
        var leftActionArray = [SKAction]()
        
        leftActionArray.append(SKAction.move(to: CGPoint(x: frame.minX - 60, y: leftCar.position.y), duration: TimeInterval(animationDuration)))
        leftActionArray.append(SKAction.removeFromParent())
        
        leftCar.run(SKAction.sequence(leftActionArray))
        
        possibleRightCars = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: possibleRightCars) as! [String]
        
        let rightCar = SKSpriteNode(imageNamed: possibleRightCars[0])
        rightCar.position = CGPoint(x: frame.minX - 60, y: bottomRoad.position.y)
        rightCar.zPosition = 1
        rightCar.setScale(0.75)
        rightCar.name = "car"
        
        self.addChild(rightCar)
            
        var rightActionArray = [SKAction]()
        
        rightActionArray.append(SKAction.move(to: CGPoint(x: frame.maxX + 60, y: rightCar.position.y), duration: TimeInterval(animationDuration)))
        rightActionArray.append(SKAction.removeFromParent())
        
        rightCar.run(SKAction.sequence(rightActionArray))
        
        
    }
    
    func setupPhysics() {
        physicsWorld.gravity = CGVector(dx: 0.0, dy: 0.0)
    }
    
    func updatePlayer (state:PlayerState) {
        if !moving {
            movePlayer(state: state)
        }

    }
    
    func movePlayer (state:PlayerState) {
        if let player = playerNode {
            player.texture = SKTexture(imageNamed: state.rawValue)
            
            var direction: CGFloat = 0
            
            switch state {
                case .up:
                    direction = 116
                case .down:
                    direction = -116
                case .neutral:
                    direction = 0
            }
            
            if Int(player.position.y) + Int(direction) >= -348 && Int(player.position.y) + Int(direction) <= 348 {
                
                moving = true
                
                let moveAction = SKAction.moveBy(x: 0, y: direction, duration: 0.3)
                
                let moveEndedAction = SKAction.run {
                    self.moving = false
                    if direction != 0 {
                        self.generator.impactOccurred()
                    }
                }
                
                let moveSequence = SKAction.sequence([moveAction, moveEndedAction])
                
                player.run(moveSequence)
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
       
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        
        if let location = touch?.location(in: self) {
            
            let nodesArray = self.nodes(at: location)
            
            let transition = SKTransition.crossFade(withDuration: 0.5)
            let gameScene = GameScene(fileNamed:"GameScene")
            gameScene?.scaleMode = .fill
            self.view?.presentScene(gameScene!, transition: transition)
        }
        
        
    }
}
