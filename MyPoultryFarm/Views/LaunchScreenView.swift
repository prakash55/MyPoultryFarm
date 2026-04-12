//
//  LaunchScreenView.swift
//  MyPoultryFarm
//
//  Created by Prakash on 12/04/26.
//

import SwiftUI

struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            // Background
            Color.white
                .ignoresSafeArea()
            
            // Launch Screen Image
            VStack {
                Spacer()
                
                Image("LaunchScreen")
                    .resizable()
                    .scaledToFit()
                    .padding()
                
                Spacer()
            }
        }
    }
}

#Preview {
    LaunchScreenView()
}
