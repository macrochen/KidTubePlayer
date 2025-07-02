import Foundation

// 这个结构体用来描述从 API 获取到的每一个分P的信息
struct VideoPart: Codable, Identifiable, Hashable {
    let cid: Int
    let page: Int
    let part: String // 这是分P的标题，比如 "P1 我的世界高端玩法"

    // 使用 cid 作为唯一标识符
    var id: Int { cid }
}

// 这是一个通用的API服务，专门获取B站视频分P列表
struct BilibiliAPIService {
    
    // 定义可能出现的错误
    enum APIError: Error {
        case invalidURL
        case networkError(Error)
        case decodingError(Error)
    }
    
    // 这是获取分P列表的核心函数
    static func fetchVideoParts(bvid: String) async throws -> [VideoPart] {
        guard let url = URL(string: "https://api.bilibili.com/x/web-interface/view?bvid=\(bvid)") else {
            throw APIError.invalidURL
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // 为了解码，我们需要定义一个匹配B站返回的JSON格式的临时结构体
            let apiResponse = try JSONDecoder().decode(BilibiliAPIResponse.self, from: data)
            
            // B站API返回的数据在 data 字段下
            return apiResponse.data.pages
            
        } catch let error as URLError {
            throw APIError.networkError(error)
        } catch let error as DecodingError {
            throw APIError.decodingError(error)
        } catch {
            throw error
        }
    }
}


// MARK: - Bilibili API JSON 解码模型
// 这部分代码只是为了让 JSONDecoder 能正确解析B站返回的数据，我们不需要直接使用它们

private struct BilibiliAPIResponse: Codable {
    let code: Int
    let message: String
    let data: APIData
}

private struct APIData: Codable {
    let pages: [VideoPart]
}