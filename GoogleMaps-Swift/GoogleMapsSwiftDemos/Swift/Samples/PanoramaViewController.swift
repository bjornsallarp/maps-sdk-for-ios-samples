// Copyright 2020 Google LLC. All rights reserved.
//
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use this
// file except in compliance with the License. You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
// ANY KIND, either express or implied. See the License for the specific language governing
// permissions and limitations under the License.

import GoogleMaps
import UIKit
import Combine

@available(iOS 13.0, *)
class PanoramaViewController: UIViewController {

  private let markerLocation = CLLocationCoordinate2D(latitude: 40.761455, longitude: -73.977814)
  private var panoramaView = GMSPanoramaView(frame: .zero)
  private var statusLabel = UILabel(frame: .zero)
  private var configured = false
  private var step = 0
  @Published private var panoIsRendered = false
  private var subscriptions = Set<AnyCancellable>()
  private var isRenderedTimer: Timer?

  override func loadView() {
    navigationController?.navigationBar.isTranslucent = false
    navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Prove bug", style: .plain, target: self, action: #selector(reproduceBug))

    panoramaView.backgroundColor = .gray
    panoramaView.delegate = self
    view = panoramaView

    statusLabel.alpha = 0.8
    statusLabel.backgroundColor = .blue
    statusLabel.textColor = .white
    statusLabel.textAlignment = .center
    statusLabel.text = "Tap 'Prove bug' multiple times. Green = rendered, Red = NOT rendered"
    view.addSubview(statusLabel)
    statusLabel.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      statusLabel.topAnchor.constraint(equalTo: view.topAnchor),
      statusLabel.heightAnchor.constraint(equalToConstant: 30),
      statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
    ])

    $panoIsRendered.dropFirst().sink { [weak self] value in
      self?.statusLabel.backgroundColor = value ? .green : .blue
      self?.statusLabel.textColor = value ? .black : .white

      if value {
        self?.isRenderedTimer?.invalidate()
      } else {
        // Change color of status to red if didFinishRendering wasn't called in 4 seconds
        self?.isRenderedTimer = Timer.scheduledTimer(withTimeInterval: 4, repeats: false, block: { [weak self] _ in
          self?.statusLabel.backgroundColor = .red
        })
      }
    }
    .store(in: &subscriptions)
  }

  @objc func reproduceBug() {
    step += 1

    if step % 2 == 0 {
      panoramaView.moveNearCoordinate(.sydney)
    } else {
      panoramaView.moveNearCoordinate(.newYork)
    }
  }
}

@available(iOS 13.0, *)
extension PanoramaViewController: GMSPanoramaViewDelegate {
  func panoramaView(_ panoramaView: GMSPanoramaView, didMove camera: GMSPanoramaCamera) {
  }

  func panoramaView(_ view: GMSPanoramaView, didMoveTo panorama: GMSPanorama?) {
    if configured { return }
    let marker = GMSMarker(position: markerLocation)
    marker.icon = GMSMarker.markerImage(with: .purple)
    marker.panoramaView = panoramaView
    let heading = GMSGeometryHeading(.newYork, markerLocation)
    panoramaView.camera = GMSPanoramaCamera(heading: heading, pitch: 0, zoom: 1)
    configured = true
  }

  func panoramaViewDidStartRendering(_ panoramaView: GMSPanoramaView) {
    statusLabel.text = "Rendering \(panoramaView.panorama?.panoramaID ?? "")"
  }

  func panoramaViewDidFinishRendering(_ panoramaView: GMSPanoramaView) {
    statusLabel.text = "Rendering \(panoramaView.panorama?.panoramaID ?? "") done"
    panoIsRendered = true
  }

  func panoramaView(_ view: GMSPanoramaView, didMoveTo panorama: GMSPanorama, nearCoordinate coordinate: CLLocationCoordinate2D) {
    statusLabel.text = "Did move to panorama \(panorama.panoramaID)"
    panoIsRendered = false
  }
}
