import UIKit
import AVKit
import AVFoundation

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private var player: AVPlayer!
    private var playerViewController: AVPlayerViewController!
    private var playerItem: AVPlayerItem!
    private var qualityButton: UIButton!
    private var videoTableView: UITableView!
    
    private let videoUrls = [
        "https://cdn.uzd.udevs.io/uzdigital/videos/76cb1319e234a59764658c0c9d566d1e/master.m3u8",
        "https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8",
        "https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8",
        "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8",
      
      
    ]
    
    private let availableQualities: [(String, Double)] = [
        ("Auto", 0),
        ("360p", 500_000),
        ("480p", 1_000_000),
        ("720p", 2_500_000),
        ("1080p", 5_000_000)
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        setupPlayer()
        setupQualityButton()
        setupTableView()
        
        playVideo(url: videoUrls[0])
        
        NotificationCenter.default.addObserver(self, selector: #selector(checkFullscreen), name: UIScreen.didConnectNotification, object: nil)
    }
    
    private func setupPlayer() {
        playerViewController = AVPlayerViewController()
        playerViewController.view.frame = CGRect(x: 0, y: 50, width: view.bounds.width, height: view.bounds.height * 0.3)
        playerViewController.view.backgroundColor = .black
        addChild(playerViewController)
        view.addSubview(playerViewController.view)
        playerViewController.didMove(toParent: self)
    }
    
    private func setupQualityButton() {
        qualityButton = UIButton(type: .system)
        qualityButton.setTitle("Change Quality", for: .normal)
        qualityButton.setTitleColor(.systemBlue, for: .normal)
        qualityButton.layer.cornerRadius = 10
        qualityButton.addTarget(self, action: #selector(changeQuality), for: .touchUpInside)
        
        qualityButton.frame = CGRect(x: 20, y: playerViewController.view.frame.maxY - 60, width: 150, height: 40)
        view.addSubview(qualityButton)
    }
    
    private func setupTableView() {
        videoTableView = UITableView()
        videoTableView.delegate = self
        videoTableView.dataSource = self
        videoTableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        videoTableView.frame = CGRect(x: 0, y: playerViewController.view.frame.maxY, width: view.bounds.width, height: view.bounds.height * 0.5)
        
        videoTableView.backgroundColor = .white
        view.addSubview(videoTableView)
    }
    
    private func playVideo(url: String) {
        guard let videoURL = URL(string: url) else { return }
        
        let newPlayerItem = AVPlayerItem(url: videoURL)
        
        if player == nil {
            player = AVPlayer(playerItem: newPlayerItem)
            playerViewController.player = player
        } else {
            player.replaceCurrentItem(with: newPlayerItem)
        }
        
        player.play()
    }
    
    
    @objc private func changeQuality() {
        let alert = UIAlertController(title: "Change Quality", message: "Select quality", preferredStyle: .actionSheet)

        for (title, bitrate) in availableQualities {
            alert.addAction(UIAlertAction(title: title, style: .default, handler: { _ in
                self.setQuality(bitrate: bitrate)
            }))
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(alert, animated: true)
    }

    private func setQuality(bitrate: Double) {
        player.currentItem?.preferredPeakBitRate = bitrate
    }

    @objc private func checkFullscreen() {
        let isFullscreen = playerViewController.isBeingPresented
        qualityButton.isHidden = isFullscreen
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videoUrls.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = "Video \(indexPath.row + 1)"
        cell.textLabel?.textColor = .black

        cell.backgroundColor = .white
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        playVideo(url: videoUrls[indexPath.row])
    }
}
