//
//  ViewController.swift
//  DogCatJudgement
//
//  Created by Kentaro Abe on 2021/02/19.
//

import UIKit
import CoreML
import Vision

class ViewController: UIViewController{
    let pickerController = UIImagePickerController()
    @IBOutlet weak var selectedImageView: UIImageView!
    @IBOutlet weak var resultTableView: UITableView!
    var results: [VNClassificationObservation] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        resultTableView.delegate = self
        resultTableView.dataSource = self
    }
    
    @IBAction func selectImageGetMethod(_ sender: Any){
        // 既存の画像から選ぶか新しく撮るかから選ぶ、ここは省略していいと思う
        let alert = UIAlertController(title: "どちらから画像を選ぶ？",
                                      message: nil,
                                      preferredStyle: .alert)
        alert.addAction(.init(title: "保存した画像から選ぶ",
                              style: .default,
                              handler: { action in
                                self.pickerController.sourceType = .savedPhotosAlbum
                                self.pickerController.delegate = self
                                
                                self.present(self.pickerController, animated: true, completion: nil)
                              }))
        alert.addAction(.init(title: "新しく撮る",
                              style: .default,
                              handler: { (action) in
                                self.pickerController.sourceType = .camera
                                self.pickerController.delegate = self
                                
                                self.present(self.pickerController, animated: true, completion: nil)
                              }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func judgement(_ image: UIImage){
        // イヌネコを判定する関数
        guard let model = try? VNCoreMLModel(for: DogCatJudgementMachine(configuration: MLModelConfiguration()).model) else{
            return
        }
        
        let request = VNCoreMLRequest(model: model){ request, error in
            // 判定が終わったときの処理
            guard let results = request.results as? [VNClassificationObservation] else{ return }
            
            self.results = results
            self.resultTableView.reloadData()
        }
        
        // UIImageをCIImageに変換する（Vision FrameworkがUIImageに対応していないので）
        guard let ciImage = CIImage(image: image) else{
            return
        }
        
        // ↑で作成したリクエストを元に、推論を行う
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        
        do{
            try handler.perform([request])
        }catch{
            let alert = UIAlertController(title: "エラー", message: "判定を正しく行えませんでした", preferredStyle: .alert)
            alert.addAction(.init(title: "OK", style: .default, handler: nil))
            
            self.present(alert, animated: true, completion: nil)
        }
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = "\(results[indexPath.row].confidence * 100)%の確率で、\(results[indexPath.row].identifier)！"
        
        return cell
    }
    
    
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage else{
            return
        }
        
        self.selectedImageView.image = image
        
        judgement(image)
        self.dismiss(animated: true, completion: nil)
    }
}
