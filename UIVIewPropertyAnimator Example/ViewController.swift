//
//  ViewController.swift
//  UIVIewPropertyAnimator Example
//
//  Created by Viswa Kodela on 6/30/19.
//  Copyright © 2019 Viswa Kodela. All rights reserved.
//

import UIKit

enum State {
    case open
    case closed
    
    var opposite: State {
        switch self {
        case .open: return .closed
        case .closed: return .open
        }
    }
}


class ViewController: UIViewController {
    
    // MARK:- Init

    // MARK:- Properties
    private var bottomConstraint: NSLayoutConstraint!
    private var currentState: State = .closed
    private var runningAnimations = [UIViewPropertyAnimator]()
    private var animationProgresses = [CGFloat]()
    private let popOverviewOffset: CGFloat = 440
    
    let popoverView: UIView = {
        let bview = UIView()
        bview.translatesAutoresizingMaskIntoConstraints = false
        bview.backgroundColor = .gray
        return bview
    }()
    
    // MARK:- Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    // MARK:- Helper Methods
    fileprivate func configureUI() {
        view.backgroundColor = .white
        
        self.popoverView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapGesture)))
        self.popoverView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture)))
        
        view.addSubview(self.popoverView)
        popoverView.widthAnchor.constraint(equalToConstant: view.frame.width).isActive = true
        popoverView.heightAnchor.constraint(equalToConstant: 600).isActive = true
        popoverView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        self.bottomConstraint = popoverView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: popOverviewOffset)
        self.bottomConstraint.isActive = true
        
    }
}

// MARK: Tap Gesture
extension ViewController {
    @objc func handleTapGesture(gesture: UITapGestureRecognizer) {
        
        let state = self.currentState.opposite
        let animator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 0.9) {
            switch state {
            case .open:
                self.bottomConstraint.constant = 0
                self.popoverView.layer.cornerRadius = 16
                self.popoverView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
                self.popoverView.layer.shadowColor = UIColor(white: 0.5, alpha: 1).cgColor
                self.popoverView.layer.shadowOffset = CGSize(width: 0, height: -1)
                self.popoverView.layer.shadowRadius = 3
                self.popoverView.layer.shadowOpacity = 0.5
            case .closed:
                self.bottomConstraint.constant = self.popOverviewOffset
                self.popoverView.layer.cornerRadius = 0
            }
            self.view.layoutIfNeeded()
        }
        
        animator.addCompletion { (position) in
            switch position {
            case .start:
                self.currentState = state.opposite
            case .end:
                self.currentState = state
            case .current:
                ()
            @unknown default:
                ()
            }
        }
        animator.startAnimation()
    }
}

// MARK:- Handle Pan gesture
extension ViewController {
    @objc func handlePanGesture(gesture: UIPanGestureRecognizer) {
        
        switch gesture.state {
        case .began:
            animateTransitionIfNeeded(to: currentState.opposite, duration: 1)
            runningAnimations.forEach({$0.pauseAnimation()})
            animationProgresses = runningAnimations.map({ $0.fractionComplete })
        case .changed:
            let translation = gesture.translation(in: self.popoverView)
            var fractionComplete = -translation.y / popOverviewOffset
            
            if currentState == .open { fractionComplete *= -1 }
            if runningAnimations[0].isReversed { fractionComplete *= -1 }
            
            // apply the new fraction
            for (index, animator) in runningAnimations.enumerated() {
                animator.fractionComplete = fractionComplete + animationProgresses[index]
            }
            
        case .ended:
            // variable setup
            let yVelocity = gesture.velocity(in: popoverView).y
            let shouldClose = yVelocity > 60
            
            // if there is no motion, continue all animations and exit early
            if yVelocity == 0 {
                runningAnimations.forEach { $0.continueAnimation(withTimingParameters: nil, durationFactor: 0) }
                break
            }
            
            switch currentState {
            case .open:
                if !shouldClose && !runningAnimations[0].isReversed { runningAnimations.forEach { $0.isReversed = !$0.isReversed } }
                if shouldClose && runningAnimations[0].isReversed { runningAnimations.forEach { $0.isReversed = !$0.isReversed } }
            case .closed:
                if shouldClose && !runningAnimations[0].isReversed { runningAnimations.forEach { $0.isReversed = !$0.isReversed } }
                if !shouldClose && runningAnimations[0].isReversed { runningAnimations.forEach { $0.isReversed = !$0.isReversed } }
            }
            
            // continue all animations
            runningAnimations.forEach { $0.continueAnimation(withTimingParameters: nil, durationFactor: 0) }
            
        @unknown default:
            ()
        }
        
    }
    
    
    private func animateTransitionIfNeeded(to state: State, duration: TimeInterval) {
        guard runningAnimations.isEmpty else {return}
        
        let transitionAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1, animations: {
            switch state {
            case .open:
                self.bottomConstraint.constant = 0
                self.popoverView.layer.cornerRadius = 20
            case .closed:
                self.bottomConstraint.constant = self.popOverviewOffset
                self.popoverView.layer.cornerRadius = 0
            }
            self.view.layoutIfNeeded()
        })
        
        transitionAnimator.addCompletion { (position) in
            switch position {
            case .start:
                self.currentState = state.opposite
            case .end:
                self.currentState = state
            case .current:
                ()
            @unknown default:
                ()
            }
            
            switch self.currentState  {
            case .open:
                self.bottomConstraint.constant = 0
            case .closed:
                self.bottomConstraint.constant = self.popOverviewOffset
            }
            self.runningAnimations.removeAll()
        }
        transitionAnimator.startAnimation()
        runningAnimations.append(transitionAnimator)
    }
}

