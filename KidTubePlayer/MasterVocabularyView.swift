import SwiftUI
import SwiftData

struct MasterVocabularyView: View {
    @Environment(\.modelContext) private var modelContext
    
    // 筛选条件的状态变量不变
    @State private var searchText: String = ""
    @State private var selectedDifficulty: Int? = nil
    
    // 核心改动：@Query 现在会根据上面的 @State 变量动态更新
    @Query private var vocabularyWords: [VocabularyWord]
    
    // 自定义构造器，用来根据筛选条件创建动态的 @Query
    init() {
        // 将 @State 变量的初始值捕获进来
        let searchText = _searchText.wrappedValue
        let selectedDifficulty = _selectedDifficulty.wrappedValue

        let predicate: Predicate<VocabularyWord>

        // 根据 selectedDifficulty 是否有值，来构建不同的 predicate
        if let difficulty = selectedDifficulty {
            // --- 情况1: 用户选择了难度 ---
            // 查询条件需要同时满足“搜索”和“难度”
            predicate = #Predicate<VocabularyWord> { word in
                (searchText.isEmpty || word.word.localizedStandardContains(searchText) || word.definition.localizedStandardContains(searchText))
                &&
                (word.difficulty == difficulty) // 在这里，difficulty 是一个解包后的 Int，不再是 Int?
            }
        } else {
            // --- 情况2: 用户未选择难度 ("All") ---
            // 查询条件只需要满足“搜索”
            predicate = #Predicate<VocabularyWord> { word in
                (searchText.isEmpty || word.word.localizedStandardContains(searchText) || word.definition.localizedStandardContains(searchText))
            }
        }

        // 使用最终确定的查询条件和固定的排序方式，来初始化 @Query
        _vocabularyWords = Query(filter: predicate, sort: [SortDescriptor(\VocabularyWord.word)])
    }
    
    var body: some View {
        List {
            // Section 1: 筛选器的 UI 保持不变
            Section(header: Text("Filters")) {
                TextField("Search words", text: $searchText)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                Picker("Difficulty", selection: $selectedDifficulty) {
                    Text("All").tag(nil as Int?)
                    Text("简单").tag(0 as Int?)
                    Text("容易").tag(1 as Int?)
                    Text("一般").tag(2 as Int?)
                    Text("困难").tag(3 as Int?)
                    Text("太难").tag(4 as Int?)
                }
                .pickerStyle(.segmented)
            }
            
            // Section 2: 列表直接使用动态更新的 vocabularyWords
            Section(header: Text("My Vocabulary")) {
                if vocabularyWords.isEmpty {
                    Text("No words found.")
                        .foregroundColor(.secondary)
                } else {
                    // ForEach 直接遍历 @Query 的结果
                    ForEach(vocabularyWords) { word in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(word.word)
                                .font(.headline)
                                .fontWeight(.bold)
                            Text(word.definition)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("Difficulty: \(difficultyString(for: word.difficulty))")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
//                                .foregroundColor(SwiftUI.Color.tertiary as! Color)
                        }
                        .padding(.vertical, 5)
                    }
                    .onDelete(perform: deleteWords)
                }
            }
        }
        .navigationTitle("我的生词本")
        .toolbar {
            EditButton()
        }
        // 不再需要 .onAppear 和 .onChange 了！视图的更新完全由 @Query 自动驱动
    }
    
    private func difficultyString(for difficulty: Int) -> String {
        switch difficulty {
        case 0: return "简单"
        case 1: return "容易"
        case 2: return "一般"
        case 3: return "困难"
        case 4: return "太难"
        default: return "未知"
        }
    }
    
    private func deleteWords(at offsets: IndexSet) {
        for index in offsets {
            // 直接从 @Query 的结果中获取要删除的对象
            let wordToDelete = vocabularyWords[index]
            modelContext.delete(wordToDelete)
        }
    }
}


// 预览部分的代码不需要修改
struct MasterVocabularyView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a temporary ModelContainer for preview
        let container: ModelContainer
        do {
            let schema = Schema([Video.self, PlaybackRecord.self, VocabularyWord.self, VideoVocabulary.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true) // Use in-memory for preview
            container = try ModelContainer(for: schema, configurations: [config])
            
            // Add some sample data for preview
            let word1 = VocabularyWord(word: "apple", definition: "苹果", difficulty: 0)
            let word2 = VocabularyWord(word: "banana", definition: "香蕉", difficulty: 1)
            let word3 = VocabularyWord(word: "cat", definition: "猫", difficulty: 2)
            let word4 = VocabularyWord(word: "dog", definition: "狗", difficulty: 3)
            let word5 = VocabularyWord(word: "elephant", definition: "大象", difficulty: 4)
            
            container.mainContext.insert(word1)
            container.mainContext.insert(word2)
            container.mainContext.insert(word3)
            container.mainContext.insert(word4)
            container.mainContext.insert(word5)
            
        } catch {
            fatalError("Failed to create ModelContainer for preview: \(error)")
        }
        
        return NavigationView {
            MasterVocabularyView()
        }
        .modelContainer(container)
    }
}
