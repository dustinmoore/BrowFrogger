//
//  GameScene.swift
//  FaceRun
//
//  Created by Brian Advent on 21.06.18.
//  Copyright © 2018 Brian Advent. All rights reserved.
//

import SpriteKit
import GameKit
import GameplayKit
import AVFoundation
import ARKit

enum PlayerState:String {
    case neutral = "Neutral"
    case up = "Up"
    case down = "Down"
}

class GameScene: SKScene, SKPhysicsContactDelegate, ARSessionDelegate {
    
    var playerNode: SKSpriteNode!
    var topRoadOne: SKSpriteNode!
    var topRoadTwo: SKSpriteNode!
    var bottomRoadOne: SKSpriteNode!
    var bottomRoadTwo: SKSpriteNode!
    var moving:Bool = false
    var anchor: ARFaceAnchor!
    var FaceAnchorsProcessedCount: Int = 0
    
    var generator:UIImpactFeedbackGenerator!
    
    var scoreLabel: SKLabelNode!
    var score:Int = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    var gameTimer: Timer!
    
    var possibleLeftCars = ["left-car-1", "left-car-2", "left-car-3", "left-car-4"]
    var possibleRightCars = ["right-car-1", "right-car-2", "right-car-3", "right-car-4"]
    
    let carCategory: UInt32 = 0x1 << 0
    let coinCategory: UInt32 = 0x1 << 1
    let playerCategory: UInt32 = 0x1 << 2
    
    var AudioPlayer = AVAudioPlayer()
    var soundOn = UserDefaults.standard.integer(forKey: "gameSound")
    
    var session:ARSession!
    
    var gameOverState = false
    var activeState = true
    
    var livesArray:[SKSpriteNode]!
    
    override func didMove(to view: SKView) {
        addLives()
        gameOverState = false
        setupPhysics()
        setupRoads()
        setupPlayerNode()
        setupScoreLabel()
        
        generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
 
        if soundOn == 1 {
            let AssortedMusics = NSURL(fileURLWithPath: Bundle.main.path(forResource: "background", ofType: "mp3")!)
            AudioPlayer = try! AVAudioPlayer(contentsOf: AssortedMusics as URL)
            AudioPlayer.prepareToPlay()
            AudioPlayer.numberOfLoops = -1
            AudioPlayer.volume = 0.5
            AudioPlayer.play()
        }
        
        score = 0
                        
        addTopCoin()
        addCar()
        
        gameTimer = Timer.scheduledTimer(timeInterval: 3.75, target: self, selector: #selector(addCar), userInfo: nil, repeats: true)
        
        session = ARSession()
        session.delegate = self
        
        guard ARFaceTrackingConfiguration.isSupported else {
            print("iPhone X or newer required")
            return
        }
        
        let configuration = ARFaceTrackingConfiguration()
        
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func addLives() {
        livesArray = [SKSpriteNode]()
        for live in 1 ... 3 {
            let liveNode = SKSpriteNode(imageNamed: "Neutral")
            liveNode.size = CGSize(width: 45, height: 45)
            let liveXPosition = frame.maxX - CGFloat(4 - live) * 45
            liveNode.position = CGPoint(x: liveXPosition, y: frame.minY + 45)
            liveNode.zPosition = 2
            print (liveNode.position)
            addChild(liveNode)
            livesArray.append(liveNode)
        }
    }

    
    func setupScoreLabel() {
        scoreLabel = SKLabelNode(text: "Score: ")
        scoreLabel.position = CGPoint(x: frame.midX, y: frame.maxY - 60)
        scoreLabel.fontColor = UIColor.white
        scoreLabel.fontName = "AvenirNext-Bold"
        scoreLabel.fontSize = 30.0
        scoreLabel.zPosition = 1
        self.addChild(scoreLabel)
    }
    
    func resetPlayerNode() {
        activeState = true;
        playerNode?.texture = SKTexture(imageNamed: "Neutral")
        playerNode?.zPosition = 1
        playerNode?.position.y = frame.midY
        playerNode?.physicsBody = SKPhysicsBody(rectangleOf: playerNode!.size)
        playerNode?.physicsBody?.categoryBitMask = playerCategory
        playerNode?.physicsBody?.isDynamic = false
        
        addChild(playerNode!)
    }
    
    func setupPlayerNode() {
        playerNode = (self.childNode(withName: "player") as! SKSpriteNode)
        playerNode?.zPosition = 1
        playerNode?.physicsBody = SKPhysicsBody(rectangleOf: playerNode!.size)
        playerNode?.physicsBody?.categoryBitMask = playerCategory
        playerNode?.physicsBody?.isDynamic = false
    }
    
    func setupRoads() {
        topRoadOne = self.childNode(withName: "topRoadOne") as? SKSpriteNode
        topRoadTwo = self.childNode(withName: "topRoadTwo") as? SKSpriteNode
        bottomRoadOne = self.childNode(withName: "bottomRoadOne") as? SKSpriteNode
        bottomRoadTwo = self.childNode(withName: "bottomRoadTwo") as? SKSpriteNode
    }
    
    func addTopCoin() {
        let topCoin = SKSpriteNode(imageNamed: "frog-coin")
        topCoin.position = CGPoint(x: frame.midX, y: frame.midY + 300)
        topCoin.zPosition = 1
        topCoin.size = CGSize(width: 35, height: 35)
        topCoin.name = "topCoin"
        
        topCoin.physicsBody = SKPhysicsBody(circleOfRadius: topCoin.size.width)
        topCoin.physicsBody?.isDynamic = true
        topCoin.physicsBody?.categoryBitMask = coinCategory
        topCoin.physicsBody?.contactTestBitMask = playerCategory
        topCoin.physicsBody?.collisionBitMask = 0
        
        self.addChild(topCoin)
    }
    
    func addBottomCoin() {
        let bottomCoin = SKSpriteNode(imageNamed: "frog-coin")
        bottomCoin.position = CGPoint(x: frame.midX, y: frame.midY - 300)
        bottomCoin.zPosition = 1
        bottomCoin.size = CGSize(width: 35, height: 35)
        bottomCoin.name = "bottomCoin"
        
        bottomCoin.physicsBody = SKPhysicsBody(circleOfRadius: bottomCoin.size.width)
        bottomCoin.physicsBody?.isDynamic = true
        bottomCoin.physicsBody?.categoryBitMask = coinCategory
        bottomCoin.physicsBody?.contactTestBitMask = playerCategory
        bottomCoin.physicsBody?.collisionBitMask = 0
        
        self.addChild(bottomCoin)
    }
    
    func addMiddleCoin() {
        let middleCoin = SKSpriteNode(imageNamed: "frog-coin")
        middleCoin.position = CGPoint(x: frame.midX, y: frame.midY)
        middleCoin.zPosition = 1
        middleCoin.size = CGSize(width: 35, height: 35)
        middleCoin.name = "middleCoin"
        
        middleCoin.physicsBody = SKPhysicsBody(circleOfRadius: middleCoin.size.width)
        middleCoin.physicsBody?.isDynamic = true
        middleCoin.physicsBody?.categoryBitMask = coinCategory
        middleCoin.physicsBody?.contactTestBitMask = playerCategory
        middleCoin.physicsBody?.collisionBitMask = 0
        
        self.addChild(middleCoin)
    }
    
    @objc func addCar () {
        possibleLeftCars = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: possibleLeftCars) as! [String]
        
        let leftCarOne = SKSpriteNode(imageNamed: possibleLeftCars[0])
        leftCarOne.position = CGPoint(x: frame.maxX + 60, y: topRoadOne.position.y)
        leftCarOne.zPosition = 1
        leftCarOne.setScale(0.75)
        leftCarOne.name = "car"
        
        leftCarOne.physicsBody = SKPhysicsBody(rectangleOf: leftCarOne.size)
        leftCarOne.physicsBody?.isDynamic = true
        leftCarOne.physicsBody?.categoryBitMask = carCategory
        leftCarOne.physicsBody?.contactTestBitMask = playerCategory
        leftCarOne.physicsBody?.collisionBitMask = 0
        
        self.addChild(leftCarOne)
        
        let animationDuration = 6
        
        var leftOneActionArray = [SKAction]()
        
        leftOneActionArray.append(SKAction.move(to: CGPoint(x: frame.minX - 60, y: leftCarOne.position.y), duration: TimeInterval(animationDuration)))
        leftOneActionArray.append(SKAction.removeFromParent())
        
        leftCarOne.run(SKAction.sequence(leftOneActionArray))
        
        let leftCarTwo = SKSpriteNode(imageNamed: possibleLeftCars[0])
        leftCarTwo.position = CGPoint(x: frame.maxX + 60, y: bottomRoadOne.position.y)
        leftCarTwo.zPosition = 1
        leftCarTwo.setScale(0.75)
        leftCarTwo.name = "car"
        
        leftCarTwo.physicsBody = SKPhysicsBody(rectangleOf: leftCarTwo.size)
        leftCarTwo.physicsBody?.isDynamic = true
        leftCarTwo.physicsBody?.categoryBitMask = carCategory
        leftCarTwo.physicsBody?.contactTestBitMask = playerCategory
        leftCarTwo.physicsBody?.collisionBitMask = 0
        
        self.addChild(leftCarTwo)
                
        var leftTwoActionArray = [SKAction]()
        
        leftTwoActionArray.append(SKAction.move(to: CGPoint(x: frame.minX - 60, y: leftCarTwo.position.y), duration: TimeInterval(animationDuration)))
        leftTwoActionArray.append(SKAction.removeFromParent())
        
        leftCarTwo.run(SKAction.sequence(leftTwoActionArray))
        
        possibleRightCars = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: possibleRightCars) as! [String]
        
        let rightCarOne = SKSpriteNode(imageNamed: possibleRightCars[0])
        rightCarOne.position = CGPoint(x: frame.minX - 60, y: bottomRoadTwo.position.y)
        rightCarOne.zPosition = 1
        rightCarOne.setScale(0.75)
        rightCarOne.name = "car"
        
        rightCarOne.physicsBody = SKPhysicsBody(rectangleOf: rightCarOne.size)
        rightCarOne.physicsBody?.isDynamic = true
        rightCarOne.physicsBody?.categoryBitMask = carCategory
        rightCarOne.physicsBody?.contactTestBitMask = playerCategory
        rightCarOne.physicsBody?.collisionBitMask = 0
        
        self.addChild(rightCarOne)
            
        var rightOneActionArray = [SKAction]()
        
        rightOneActionArray.append(SKAction.move(to: CGPoint(x: frame.maxX + 60, y: rightCarOne.position.y), duration: TimeInterval(animationDuration)))
        rightOneActionArray.append(SKAction.removeFromParent())
        
        rightCarOne.run(SKAction.sequence(rightOneActionArray))
        
        let rightCarTwo = SKSpriteNode(imageNamed: possibleRightCars[0])
        rightCarTwo.position = CGPoint(x: frame.minX - 60, y: topRoadTwo.position.y)
        rightCarTwo.zPosition = 1
        rightCarTwo.setScale(0.75)
        rightCarTwo.name = "car"
        
        rightCarTwo.physicsBody = SKPhysicsBody(rectangleOf: rightCarOne.size)
        rightCarTwo.physicsBody?.isDynamic = true
        rightCarTwo.physicsBody?.categoryBitMask = carCategory
        rightCarTwo.physicsBody?.contactTestBitMask = playerCategory
        rightCarTwo.physicsBody?.collisionBitMask = 0
        
        self.addChild(rightCarTwo)
            
        var rightTwoActionArray = [SKAction]()
        
        rightTwoActionArray.append(SKAction.move(to: CGPoint(x: frame.maxX + 60, y: rightCarTwo.position.y), duration: TimeInterval(animationDuration)))
        rightTwoActionArray.append(SKAction.removeFromParent())
        
        rightCarTwo.run(SKAction.sequence(rightTwoActionArray))
        
        
    }
    
    func setupPhysics() {
        physicsWorld.gravity = CGVector(dx: 0.0, dy: 0.0)
        physicsWorld.contactDelegate = self
    }
    
    func updatePlayer (state:PlayerState) {
        if !moving {
            movePlayer(state: state)
        }

    }
    
    func movePlayer (state:PlayerState) {
        if !gameOverState && activeState {
            if let player = playerNode {
                print (player.position.y)
                if player.position.y > -299.99 && player.position.y < 299.99 {
                    player.texture = SKTexture(imageNamed: state.rawValue)
                } else {
                    player.texture = SKTexture(imageNamed: "Neutral")
                }
                
                var direction: CGFloat = 0
                
                switch state {
                    case .up:
                        direction = 100
                        if player.position.y < 299.99 {
                            self.run(SKAction.stop())
                            self.run(SKAction.playSoundFileNamed("jump.mp3", waitForCompletion: false))
                        }
                    case .down:
                        direction = -100
                        if player.position.y > -299.99 {
                            self.run(SKAction.stop())
                            self.run(SKAction.playSoundFileNamed("jump.mp3", waitForCompletion: false))
                        }
                    case .neutral:
                        direction = 0
                }
                
                if Int(player.position.y) + Int(direction) >= -300 && Int(player.position.y) + Int(direction) <= 300 {
                    
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
    }
    
    func gameOver() {
        if soundOn == 1 {
            AudioPlayer.stop()
        }
        
        let gameOverLabel = SKLabelNode(text: "Game Over!")
        gameOverLabel.fontName = "AvenirNext-Bold"
        gameOverLabel.fontSize = 50.0
        gameOverLabel.fontColor = UIColor.white
        gameOverLabel.position = CGPoint(x: frame.midX, y: frame.midY)
        gameOverLabel.zPosition = 1
        addChild(gameOverLabel)
        animate(label: gameOverLabel)
        
        UserDefaults.standard.set(score, forKey: "RecentScore")
        if score > UserDefaults.standard.integer(forKey: "Highscore") {
            saveHighscore(gameScore: score)
            UserDefaults.standard.set(score, forKey: "Highscore")
        }
        
        print("game over")
    }
    
    func animate(label: SKLabelNode) {
        let fadeOut = SKAction.fadeOut(withDuration: 0.75)
        let fadeIn = SKAction.fadeIn(withDuration: 0.75)
        
        let sequence = SKAction.sequence([fadeOut, fadeIn])
        label.run(SKAction.repeatForever(sequence))
    }
    
    func goToMenuScreen() {
        let transition = SKTransition.crossFade(withDuration: 0.5)
        let menuScene = MenuScene(fileNamed:"MenuScene")
        menuScene?.scaleMode = .fill
        self.view?.presentScene(menuScene!, transition: transition)
    }
    
    //sends the highest score to leaderboard
    func saveHighscore(gameScore: Int) {
        print ("You have a high score!")
        print("\n Attempting to authenticating with GC...")
        
        if GKLocalPlayer.local.isAuthenticated {
            print("\n Success! Sending highscore of \(score) to leaderboard")
            
            let my_leaderboard_id = "HIGHSCOREASTEROIDCATCHER2020"
            let scoreReporter = GKScore(leaderboardIdentifier: my_leaderboard_id)
            
            scoreReporter.value = Int64(gameScore)
            let scoreArray: [GKScore] = [scoreReporter]
            
            GKScore.report(scoreArray, withCompletionHandler: {error -> Void in
                if error != nil {
                    print("An error has occured:")
                    print("\n \(String(describing: error)) \n")
                }
            })
        }
    }
    
    // MARK: ARSession Delegate
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        if let faceAnchor = anchors.first as? ARFaceAnchor {
            update(withFaceAnchor: faceAnchor)
        }
        
    }
    
    func update(withFaceAnchor faceAnchor: ARFaceAnchor) {
        let bledShapes:[ARFaceAnchor.BlendShapeLocation:Any] = faceAnchor.blendShapes    
        
        guard let browInnerUp = bledShapes[.browInnerUp] as? Float else {return}
        
        if browInnerUp > 0.25 {
            updatePlayer(state: .up)
        } else if browInnerUp < 0.065 {
            updatePlayer(state: .down)
        } else {
            updatePlayer(state: .neutral)
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
       
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let contactMask = contact.bodyA.categoryBitMask
        
        if contactMask == playerCategory {
            let randomInt = Int.random(in: 1..<3)
            if (contact.bodyB.node?.name == "car") {
                if let player = playerNode {
                    player.texture = SKTexture(imageNamed: "Dead")
                }
                if self.livesArray.count > 0 && activeState  {
                    activeState = false;
                    let liveNode = self.livesArray.first
                    liveNode!.removeFromParent()
                    self.livesArray.removeFirst()
                    
                    if self.livesArray.count > 0 {
                        let sound = SKAction.playSoundFileNamed("dead.mp3", waitForCompletion: true)
                        let delay = SKAction.wait(forDuration: 0.25)
                        let reset = SKAction.run({self.resetPlayerNode()})
                        let remove = SKAction.run({self.playerNode?.removeFromParent()})
                        let sequence = SKAction.sequence([sound, delay, remove, reset])
                        self.run(sequence)
                                                
                    } else {
                        self.gameOverState = true
                        self.run(SKAction.playSoundFileNamed("fail.mp3", waitForCompletion: false))
                        self.gameOver()
                        let delay = SKAction.wait(forDuration: 5.0)
                        let newGame = SKAction.run({self.goToMenuScreen()})
                        let sequence = SKAction.sequence([delay, newGame])
                        self.run(sequence)
                    }
                }
            } else if (contact.bodyB.node?.name == "topCoin") {
                let topCoin = contact.bodyB.node as? SKSpriteNode
                topCoin?.removeFromParent()
                self.run(SKAction.playSoundFileNamed("coin.mp3", waitForCompletion: false))
                score += 1
                if randomInt == 1 {
                    addBottomCoin()
                } else {
                    addMiddleCoin()
                }
                print(score)
            } else if (contact.bodyB.node?.name == "bottomCoin") {
                let bottomCoin = contact.bodyB.node as? SKSpriteNode
                bottomCoin?.removeFromParent()
                self.run(SKAction.playSoundFileNamed("coin.mp3", waitForCompletion: false))
                score += 1
                if randomInt == 1 {
                    addTopCoin()
                } else {
                    addMiddleCoin()
                }
                print(score)
            } else if (contact.bodyB.node?.name == "middleCoin") {
                let middleCoin = contact.bodyB.node as? SKSpriteNode
                middleCoin?.removeFromParent()
                self.run(SKAction.playSoundFileNamed("coin.mp3", waitForCompletion: false))
                score += 1
                if randomInt == 1 {
                    addTopCoin()
                } else {
                    addBottomCoin()
                }
                print(score)
            }
        }
    }
}
