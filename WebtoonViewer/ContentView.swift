//
//  ContentView.swift
//  WebtoonViewer
//
//  Created by Kim Yong Ha on 2021/12/12.
//

import SwiftUI
import SwiftSoup

struct ContentView: View {
    var body: some View {
        WebtoonView()
    }
}

struct WebtoonView: View {
    @State private var webtoons: [Webtoon] = [Webtoon]()
    @State private var editMode = EditMode.inactive
    
    init() {
        UINavigationBar.appearance().backgroundColor = .systemGray6
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(webtoons.indices, id: \.self) { idx in
                    WebtoonItem(webtoon: $webtoons[idx])
                }
                .onDelete(perform: self.delete)
                .onMove(perform: self.move)
            }
            .listStyle(PlainListStyle())
            .navigationBarItems(leading: EditButton(), trailing: addButton)
            .navigationTitle("Naver Webtoon")
            .environment(\.editMode, $editMode)
        }
    }
    
    private var addButton: some View {
        switch editMode {
        case .inactive:
            return AnyView(NavigationLink(destination: AddView(webtoons: self.$webtoons)){
                Image(systemName: "plus")
            })
        default:
            return AnyView(EmptyView())
        }
    }
    
    func delete(at offsets: IndexSet) {
        self.webtoons.remove(atOffsets: offsets)
    }
    
    func move(source: IndexSet, destination: Int) {
        self.webtoons.move(fromOffsets: source, toOffset: destination)
    }
}

struct WebtoonItem: View {
    @Binding var webtoon: Webtoon
    
    init(webtoon: Binding<Webtoon>) {
        self._webtoon = webtoon
    }
    
    var body: some View {
        HStack(alignment: .center) {
            NavigationLink(destination: TitleView(webtoon: $webtoon)) {
                Image(uiImage: UIImage(data: webtoon.data)!)
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .cornerRadius(20)
                VStack(alignment: .leading) {
                    Text(webtoon.title)
                        .font(.title)
                        .padding(.leading, 4)
                    if webtoon.details != "" {
                        Text(webtoon.details)
                            .font(.subheadline)
                            .lineLimit(1)
                    }
                }
            }
        }
    }
}

struct AddView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var webtoons: [Webtoon]
    @State private var webtoon: Webtoon? = nil
    @State private var titleIdx: String = ""
    @State private var details: String = ""
    @State private var data: Data? = nil
    
    var body: some View {
        List {
            if self.webtoon != nil {
                HStack(alignment: .center) {
                    Image(uiImage: UIImage(data: webtoon!.data)!)
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .cornerRadius(20)
                    VStack(alignment: .leading) {
                        Text(webtoon!.title)
                            .font(.title)
                            .padding(.leading, 4)
                        if details != "" {
                            Text(details)
                                .font(.subheadline)
                                .lineLimit(1)
                        }
                    }
                }
            }
            TextField("웹툰 코드", text: $titleIdx)
            TextField("설명", text: $details)
        }
        .navigationTitle("Add Webtoon")
        .listStyle(GroupedListStyle())
        HStack {
            Button(action: self.load) {
                Text("Load")
            }
            .padding()
            Spacer()
            Button(action: self.add) {
                Image(systemName: "plus")
            }
            .padding()
        }
    }
    
    func load() {
        if (self.titleIdx == "") {
            
        } else {
            Task {
                await loadWebtoon(titleIdx: Int(titleIdx)!, add: false)
            }
        }
    }
    
    func add() {
        if (self.titleIdx == "") {
            
        } else {
            if (self.webtoon == nil) {
                Task {
                    await loadWebtoon(titleIdx: Int(titleIdx)!, add: true)
                }
            } else {
                webtoon!.details = self.details
                self.webtoons.append(self.webtoon!)
            }
        }
        self.presentationMode.wrappedValue.dismiss()
    }
    
    func loadWebtoon(titleIdx: Int, add: Bool) async {
        var html: String = ""
        requestTitles(title: titleIdx, page: 1) { (success, data) in
            html = String(data: data, encoding: .utf8) ?? ""
        }
        while(html == "") {}
        do {
            let doc: Document = try SwiftSoup.parse(html)
            let links: Element = try doc.select("div").get(0)
            let info = try links.select("div").get(15)
            let details = try info.select("div").get(1)
                .select("div").get(1)
                .select("img").get(0)
            let thumbnail: String = try details.attr("src")
            let title: String = try details.attr("title")
            await requestImage(uri: thumbnail) { (success, data) in
                self.webtoon = Webtoon(data: data, title: title, titleIdx: titleIdx, details: self.details, seen: 0)
                if add {
                    self.webtoons.append(self.webtoon!)
                }
            }
        } catch {
            print("Error")
        }
    }
}

struct TitleView: View {
    @State private var titles: [(Data?, Title)] = [(Data?, Title)]()
    @State private var action: Int? = 0
    @Binding var webtoon: Webtoon
    @State private var last: Int = 1
    
    var body: some View {
        ZStack {
            ForEach(self.titles.indices, id: \.self) { i in
                NavigationLink(destination: ImageView(webtoon: self.$webtoon, titleName: titles[i].1.title, titleIdx: webtoon.titleIdx, toonIndex: titles[i].1.index), tag: titles[i].1.index, selection: $action) {
                    EmptyView()
                }
            }
        }
        List {
            HStack {
                Text("이어보기: \(webtoon.seen)")
                    .scaledToFit()
                    .onTapGesture {
                        self.action = webtoon.seen
                    }
                    .padding()
                Spacer()
                Text("첫화 보기")
                    .scaledToFit()
                    .onTapGesture {
                        self.action = 1
                    }
                    .padding()
            }
            ForEach(self.titles.indices, id: \.self) { i in
                HStack {
                    VStack {
                        HStack(alignment: .center) {
                            if titles[i].0 == nil {
                                ProgressView()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .cornerRadius(20)
                            } else {
                                Image(uiImage: UIImage(data: titles[i].0!)!)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .cornerRadius(20)
                            }
                            
                            VStack {
                                Text(titles[i].1.title)
                                    .padding(4)
                                    .background(Color.init(hue: 0, saturation: 0.13, brightness: 1, opacity: 0.5))
                                    .foregroundColor(.black)
                                    .cornerRadius(20)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 1)
                        .padding(.leading, 3)
                        NavigationLink(destination: CommentView(title: titles[i].1)) {
                            Text("Comments")
                        }
                    }
                    .onTapGesture {
                        self.action = titles[i].1.index;
                    }
                }
                .onAppear {
                    if self.titles[i].0 == nil {
                        Task {
                            await requestImage(uri: self.titles[i].1.url) { (success, data) in
                                self.titles[i].0 = data
                            }
                        }
                    }
                }
            }
        }
        .navigationBarTitle(webtoon.title)
        .listStyle(PlainListStyle())
        .task() {
            await loadTitles()
        }
    }
    
    func loadTitles() async {
        Task {
            var page: Int = self.last
            var limit: Int = self.last
            
            while(page <= limit && page <= self.last + 5 ) {
                var html: String = ""
                requestTitles(title: webtoon.titleIdx, page: page) { (success, data) in
                    html = String(data: data, encoding: .utf8) ?? ""
                }
                while(html == "") {}
                do {
                    let doc: Document = try SwiftSoup.parse(html)
                    let links: Element = try doc.select("div").get(0)
                    let info = try links.select("div").get(15)
                    let list = try info.select("tr")
                    if list.count < 4 {
                        return
                    }
                    
                    for i in 2...(list.count - 2) {
                        let tmp = try list[i].select("td").get(0)
                            .select("img").get(0)
                        let title_name = try tmp.attr("title")
                        let title_thumb = try tmp.attr("src")
                        let title_idx = Int(title_thumb.getArrayAfterRegex(regex: "[0-9]+")[1]) ?? 0

                        if i == 2 && page == 1 {
                            limit = title_idx/10 + 1
                        }
                        
                        self.titles.append((nil, Title(url: title_thumb, title: title_name, titleIdx: webtoon.titleIdx, index: title_idx)))
                    }
                } catch {
                    print("Error")
                }
                
                page += 1
            }
            
            self.last +=  5
        }
    }
}

struct ImageView: View {
    @State private var urls: [String] = [String]()
    @Binding var webtoon: Webtoon
    let titleName: String
    let titleIdx: Int
    let toonIndex: Int
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(self.urls.indices, id: \.self) { i in
                    ImageItem(url: urls[i])
                }
            }
        }
        .listStyle(PlainListStyle())
        .navigationBarTitle(self.titleName)
        .task() {
            await loadImages()
        }
        .onDisappear {
            if (self.webtoon.seen < toonIndex) {
                self.webtoon.seen = toonIndex
            }
        }
    }
    
    func loadImages() async {
        var html: String = ""
        requestList(title: self.titleIdx, num: self.toonIndex) { (success, data) in
            html = String(data: data, encoding: .utf8) ?? ""
        }
        while(html == "") {}
        do {
            let doc: Document = try SwiftSoup.parse(html)
            var links: Element = try doc.select("div").get(0)
            links = try links.select("div").get(35)
            
            let images: Elements = try links.select("img")
            Task {
                for k: Element in images {
                    let string: String = try k.attr("src")
                    if (string == "") {
                        continue
                    }

                    self.urls.append(string)
                }
            }
        } catch {
            print("Error")
        }
    }
}

struct ImageItem: View {
    @State private var data: Data? = nil
    @State private var finished: Bool = false
    let url: String
    
    var body: some View {
        VStack {
            if data == nil {
                ProgressView()
                .aspectRatio(contentMode: .fill)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .frame(width: 690, height: 1600)
            } else {
                Image(uiImage: UIImage(data: data!)!)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
            }
        }
        .onAppear {
            if finished == false {
                loadImage()
            }
        }
    }
    
    func loadImage() {
        print(url)
        Task {
            await requestImage(uri: url) { (success, data) in
                self.data = data;
            }
        }
        finished = true
    }
}

struct CommentView: View {
    @State private var comments: [Comment] = [Comment]();
    @State private var finished: Bool = false
    let title: Title
    
    var body: some View {
        VStack {
            if comments.isEmpty {
                ProgressView()
                .aspectRatio(contentMode: .fill)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .frame(width: 690, height: 1600)
            } else {
                List(self.comments.indices, id: \.self) { i in
                    VStack(alignment: .leading) {
                        Text(comments[i].userName)
                        Text(comments[i].contents)
                    }
                }
            }
        }
        .task {
            requestComment(title: title.titleIdx, no: title.index) { (success, data) in
                var string: String = String(data: data, encoding: .utf8)!
                let range = string.startIndex..<string.index(string.startIndex, offsetBy: 10)
                string.removeSubrange(range)
                string.removeLast()
                string.removeLast()
                print(string)
                let json = try! (JSONSerialization.jsonObject(with: string.data(using: .utf8)!, options: []) as? [String: Any])
                let result: [String: Any] = json!["result"] as! [String : Any]
                let commentList: [[String: Any]] = result["commentList"] as! [[String: Any]]
                for i in commentList {
                    if (i["best"] as! Bool) {
                        comments.append(Comment(userName: i["userName"]! as! String, contents: i["contents"]! as! String))
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
