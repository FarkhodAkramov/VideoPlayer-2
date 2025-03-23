import UIKit
import AVKit
import AVFoundation

class CustomAVPlayerViewController: AVPlayerViewController {
    var qualities: [(String, URL)] = []
    var currentTime: CMTime = .zero
}

class ViewController: UIViewController {
    @IBOutlet weak var platBtn: UIButton!
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    
    let videoUrls = [
        "https://devstreaming-cdn.apple.com/videos/streaming/examples/adv_dv_atmos/main.m3u8",
        "https://devstreaming-cdn.apple.com/videos/streaming/examples/adv_dv_atmos/main.m3u8",
        "https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8",
        "https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8",
        "https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8",
        "https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8",
        "https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8",
        "https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8",
        "https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8",
        "https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8"
    ]
    var qualities: [(String, URL)] = []
    var customPlayerVC: CustomAVPlayerViewController?
    var playingIndex: Int?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "VideoPlayerTVC", bundle: nil), forCellReuseIdentifier: "VideoPlayerTVC")
        playVideo(at: 0)  // Play the first video by default
    }
    
    func playVideo(at index: Int) {
        playingIndex = index
        customPlayerVC?.currentTime = .zero
        parseM3U8(urlString: videoUrls[index])
        tableView.reloadData()
    }
    
    func parseM3U8(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else { return }
            if let playlist = String(data: data, encoding: .utf8) {
                self.extractQualities(from: playlist, baseURL: url.deletingLastPathComponent())
            }
        }.resume()
    }
    
    func extractQualities(from playlist: String, baseURL: URL) {
        qualities.removeAll()
        let lines = playlist.components(separatedBy: "\n")
        for i in 0..<lines.count where lines[i].contains("RESOLUTION=") {
            if let resolution = lines[i].components(separatedBy: "RESOLUTION=").last?.components(separatedBy: ",").first,
               i + 1 < lines.count {
                let videoURL = lines[i + 1]
                if let qualityURL = URL(string: videoURL, relativeTo: baseURL) {
                    qualities.append((resolution, qualityURL))
                }
            }
        }
        DispatchQueue.main.async {
            self.addPlayerView(url: self.qualities.first?.1 ?? baseURL, resumeTime: self.customPlayerVC?.currentTime ?? .zero)
        }
    }
    
    func addPlayerView(url: URL, resumeTime: CMTime) {
        customPlayerVC?.player?.pause()
        customPlayerVC?.view.removeFromSuperview()
        customPlayerVC?.removeFromParent()
        
        let playerItem = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: playerItem)
        customPlayerVC = CustomAVPlayerViewController()
        customPlayerVC!.qualities = qualities
        addChild(customPlayerVC!)
        customPlayerVC!.view.frame = playerView.bounds
        playerView.addSubview(customPlayerVC!.view)
        customPlayerVC!.didMove(toParent: self)
        
        customPlayerVC!.player = player
        player.seek(to: resumeTime)
        player.play()
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
        addQualityButton()
    }
    
    @objc func playerDidFinishPlaying() {
        guard let index = playingIndex else { return }
        let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? VideoPlayerTVC
        cell?.lbl.textColor = .green  // Change text color when video finishes
    }
    
    func addQualityButton() {
        let qualityButton = UIButton(type: .system)
        qualityButton.setTitle("Quality", for: .normal)
        qualityButton.addTarget(self, action: #selector(showQualityOptions), for: .touchUpInside)
        qualityButton.translatesAutoresizingMaskIntoConstraints = false
        playerView.addSubview(qualityButton)
        NSLayoutConstraint.activate([
            qualityButton.leadingAnchor.constraint(equalTo: playerView.leadingAnchor, constant: 16),
            qualityButton.bottomAnchor.constraint(equalTo: playerView.bottomAnchor, constant: -16)
        ])
    }
    
    @objc func showQualityOptions() {
        let alert = UIAlertController(title: "Select Quality", message: nil, preferredStyle: .actionSheet)
        for (resolution, url) in qualities {
            alert.addAction(UIAlertAction(title: resolution, style: .default, handler: { _ in
                self.changeQuality(url: url)
            }))
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func changeQuality(url: URL) {
        guard let player = customPlayerVC?.player else { return }
        customPlayerVC?.currentTime = player.currentTime()
        customPlayerVC?.player?.pause()
        addPlayerView(url: url, resumeTime: customPlayerVC?.currentTime ?? .zero)
    }
}

//MARK: - Table View -
extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        videoUrls.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "VideoPlayerTVC", for: indexPath) as! VideoPlayerTVC
        cell.lbl.text = "Video №\(indexPath.row + 1)"
        cell.lbl.textColor = (indexPath.row == playingIndex) ? .blue : .black
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        playVideo(at: indexPath.row)
    }
}
