//
//  ContentView.swift
//  MapKitFeatures
//
//  Created by David Grammatico on 04/07/2023.
//

import SwiftUI
import MapKit

struct ContentView: View {
    @State private var cameraPosition: MapCameraPosition = .region(.userRegion)
    @State private var searchText = ""
    @State private var results: [MKMapItem] = []
    @State private var mapSelection: MKMapItem?
    @State private var showDetails = false
    @State private var getDirections = false
    @State private var routeDisplaying = false
    @State private var route: MKRoute?
    @State private var routeDestination: MKMapItem?
    var body: some View {
        Map(position: $cameraPosition, selection: $mapSelection) {
            Annotation("My location", coordinate: .userLocation) {
                ZStack {
                    Circle()
                        .frame(width: 32, height: 32)
                        .foregroundColor(.blue.opacity(0.25))
                    Circle()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.white)
                    Circle()
                        .frame(width: 12, height: 12)
                        .foregroundColor(.blue)
                }
            }
            ForEach(results, id: \.self) { item in
                if routeDisplaying {
                    if item == routeDestination {
                        let placemark = item.placemark
                        Marker(placemark.name ?? "",systemImage:"paperplane" , coordinate: placemark.coordinate)
                    }
                } else {
                    let placemark = item.placemark
                    Marker(placemark.name ?? "",systemImage:"paperplane" , coordinate: placemark.coordinate)
                }
            }
            if let route {
                MapPolyline(route.polyline)
                    .stroke(.blue, lineWidth: 6)
            }
        }
        .overlay(alignment: .top, content: {
            TextField("Search for a location", text: $searchText)
                .font(.subheadline)
                .padding(12)
                .background(.white )
                .cornerRadius(10)
                .padding()
                .shadow(radius: 10)
        })
        .onChange(of: mapSelection, { oldValue, newValue in
            showDetails = newValue != nil
        })
        .onChange(of: getDirections, { oldValue, newValue in
            if newValue {
                fetchRoute()
            }
        })
        .onSubmit(of: .text) {
            Task {
                await SearchPlaces()
            }
        }
        .sheet(isPresented: $showDetails, content: {
            LocationDetailView(mapSelection: $mapSelection, show: $showDetails, getDirections: $getDirections)
                .presentationDetents([.height(340)])
                .presentationBackgroundInteraction(.enabled(upThrough: .height(340)))
                .presentationCornerRadius(12)
        })
        .mapControls {
            MapCompass()
            MapPitchButton()
            MapUserLocationButton()
        }
    }
}

extension ContentView {
    func SearchPlaces() async {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = .userRegion
        let results = try? await MKLocalSearch(request: request).start()
        self.results = results?.mapItems ?? []
    }
    func fetchRoute() {
        if let mapSelection {
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: .init(coordinate: .userLocation))
            request.destination = mapSelection
            request.transportType = .walking
            
            Task {
                let result = try? await MKDirections(request: request).calculate()
                route = result?.routes.first
                routeDestination = mapSelection
                withAnimation(.snappy) {
                    routeDisplaying = true
                    showDetails = false
                    if let rect = route?.polyline.boundingMapRect, routeDisplaying {
                        cameraPosition = .rect(rect)
                    }
                }
            }
        }
    }
}

extension CLLocationCoordinate2D {
    static var userLocation: CLLocationCoordinate2D {
        return .init(latitude: 48.8566, longitude: 2.3522)
    }
}

extension MKCoordinateRegion {
    static var userRegion: MKCoordinateRegion {
        return .init(center: .userLocation, latitudinalMeters: 1000, longitudinalMeters: 1000)
    }
}

#Preview {
    ContentView()
}
