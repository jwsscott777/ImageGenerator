//
//  ContentView.swift
//  ImageGenerator
//
//  Created by JWSScott777 on 12/14/22.
//
import OpenAIKit
import SwiftUI

final class ViewModel: ObservableObject {

   

    private var openai: OpenAI?

    func setup() {
          openai = OpenAI(Configuration(organization: "Personal", apiKey: Constants.key))
    }

    func generateImage(prompt: String) async -> UIImage? {
        guard let openai = openai else { return nil }

        do {
            let params = ImageParameters(
                prompt: prompt,
                resolution: .medium,
                responseFormat: .base64Json
            )
            let result = try await openai.createImage(parameters: params)
            let data = result.data[0].image
            let image = try openai.decodeBase64Image(data)
            return image
        } catch {
            print(String(describing: error))
            return nil
        }
    }


}

struct ContentView: View {
    @ObservedObject var viewModel = ViewModel()
    @State private var text = ""
    @State private var image: UIImage?
    @State private var isLoading: Bool = false
    @FocusState private var descFocused: Bool

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio( contentMode: .fit)
                        .frame(width: 300, height: 300)
                    Button("Save Image") {
                        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                    }
                } else {
                    if !isLoading {
                        Text("Type in prompt to create image")
                            .padding(.top)
                    } else {
                        Rectangle()
                            .fill(Color.purple)
                            .frame(width: 256, height: 256)
                        .overlay {
                            if isLoading {
                                VStack {
                                    ProgressView()
                                    Text("Loading...")
                                }
                            }
                        }
                    }
                }

                TextField("Type in prompt here...", text: $text)
                    .textFieldStyle(.roundedBorder)
                    .focused($descFocused)
                    .padding()
                Button("Generate") {
                    isLoading = true
                    if !text.trimmingCharacters(in: .whitespaces).isEmpty {
                        descFocused = false

                        Task {
                            let result = await viewModel.generateImage(prompt: text)
                            text = ""
                            if result == nil {
                                print("Failed to get image")
                            }

                            self.image = result
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            }
            .navigationTitle("JS Image Maker")
            .onAppear {
                viewModel.setup()
            }
        }

    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
