import UIKit
import PhotosUI
import PDFKit

class ViewController: UIViewController, PHPickerViewControllerDelegate {
    
    var selectedImages: [UIImage] = []
    @IBOutlet weak var collectionView: UICollectionView! // Cambiamos el IBOutlet al CollectionView
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = self
        collectionView.delegate = self
    }
    
    // MARK: - PHPickerViewControllerDelegate
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)
        
        selectedImages.removeAll()
        
        for result in results {
            result.itemProvider.loadObject(ofClass: UIImage.self) { (object, error) in
                if let image = object as? UIImage {
                    self.selectedImages.append(image)
                    DispatchQueue.main.async {
                        self.collectionView.reloadData() // Actualizamos la colección cuando se seleccionan nuevas imágenes
                    }
                }
            }
        }
        
        if !selectedImages.isEmpty {
            createPDF()
        } else {
            print("No se han seleccionado imágenes para generar el PDF.")
        }
    }
    
    // MARK: - Actions
    
    @IBAction func elegirfotosgaleria(_ sender: Any) {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 0
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    // MARK: - Helper Methods
    
    func createPDF() {
        let pdfDocument = PDFDocument()
        for image in selectedImages {
            if let pdfPage = PDFPage(image: image) {
                pdfDocument.insert(pdfPage, at: pdfDocument.pageCount)
            }
        }
        
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Error al obtener el directorio de documentos.")
            return
        }
        
        let pdfURL = documentsDirectory.appendingPathComponent("output.pdf")
        
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        let pageCount = pdfDocument.pageCount
        do {
            try pdfRenderer.writePDF(to: pdfURL) { context in
                for i in 0..<pageCount {
                    let pdfPage = pdfDocument.page(at: i)!
                    let image = pdfPage.thumbnail(of: CGSize(width: 612, height: 792), for: .artBox)
                    context.beginPage()
                    image.draw(in: CGRect(x: 0, y: 0, width: 612, height: 792))
                }
            }
            
            print("PDF generado: \(pdfURL)")
            
            sharePDF(at: pdfURL)
        } catch {
            print("Error al generar el PDF: \(error)")
        }
    }
    
    func sharePDF(at url: URL) {
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        present(activityViewController, animated: true, completion: nil)
    }
    
    class CustomCollectionViewCell: UICollectionViewCell {
        @IBOutlet weak var imageView: UIImageView!
    }
}

// MARK: - UICollectionViewDataSource
extension ViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return selectedImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CustomCell", for: indexPath) as? CustomCollectionViewCell else {
            fatalError("La celda no es una instancia de CustomCollectionViewCell")
        }
        
        let image = selectedImages[indexPath.item]
        cell.imageView.image = image
        
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension ViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 100, height: 100) // Tamaño de cada celda en la vista de colección
    }
}



