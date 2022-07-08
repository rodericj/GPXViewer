//
//  ActionViewController.swift
//  POSTGPXURLExtension
//
//  Created by Roderic Campbell on 7/8/22.
//

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers
import DataFetch

class ActionViewController: UIViewController {

    //    @IBOutlet weak var imageView: UIImageView!
    let fetcher = DataFetcher()

    override func viewDidLoad() {
        super.viewDidLoad()
        print("view did load")
        // Get the item[s] we're handling from the extension context.
        
        // For example, look for an image and place it into an image view.
        // Replace this with something appropriate for the type[s] your extension supports.
        print("inputItems: ", self.extensionContext!.inputItems)
        for item in self.extensionContext!.inputItems as! [NSExtensionItem] {
            print("attachments: ", item.attachments)
            for provider in item.attachments! {

                if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                    // This is an image. We'll load it, then place it in our image view.
                    print("we have items that conform")
                    provider.loadItem(
                        forTypeIdentifier: UTType.fileURL.identifier,
                        options: nil,
                        completionHandler: { (url, error) in
                            if let error = error {
                                print("Got an error \(error)")
                            }
                            guard let dataURL = url as? URL else {
                                print("not data")
                                return
                            }

                            var request = URLRequest(url: URL(string: "https://38e2dda5cbac.ngrok.io/upload?key=gaia.gpx")!)
                            request.httpMethod = "POST"

                            do {
                                request.httpBody = try Data(contentsOf: dataURL)
                            } catch {
                                print("could not set body")
                            }

                            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                                if let error = error {
                                    print("error posting \(error)")
                                }
                                if let data = data {
                                    print("some kind of data came back \(data)")
                                }
                                if let response = response {
                                    print("we got a response \(response)")
                                }
                            }
                            task.resume()
                            //                        OperationQueue.main.addOperation {
                            //                            if let strongImageView = weakImageView {
                            //                                if let imageURL = imageURL as? URL {
                            //                                    strongImageView.image = UIImage(data: try! Data(contentsOf: imageURL))
                            //                                }
                            //                            }
                            //                        }
                        })
                    break
                }
            }
        }
    }

    @IBAction func done() {
        // Return any edited content to the host app.
        // This template doesn't do anything, so we just echo the passed in items.
        self.extensionContext!.completeRequest(returningItems: self.extensionContext!.inputItems, completionHandler: nil)
    }

}
