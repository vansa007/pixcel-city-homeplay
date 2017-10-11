//
//  PopViewController.swift
//  pixcel-city-homeplay
//
//  Created by Vansa Pha on 10/11/17.
//  Copyright © 2017 Vansa Pha. All rights reserved.
//

import UIKit

class PopViewController: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var popImageView: UIImageView!
    var passedImage: UIImage!
    
    func initData(forImage image: UIImage) {
        self.passedImage = image
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        popImageView.image = passedImage
        addDoubleTapDismiss()
    }
    
    func addDoubleTapDismiss() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(dismissView))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        view.addGestureRecognizer(doubleTap)
    }
    
    @objc func dismissView() {
        dismiss(animated: true, completion: nil)
    }

}
