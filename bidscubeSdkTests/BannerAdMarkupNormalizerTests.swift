import Testing
#if SWIFT_PACKAGE
@testable import BidscubeSDKAppLovin
#else
@testable import BidscubeSDK
#endif

@Suite(.serialized)
struct BannerAdMarkupNormalizerTests {
    @Test func leavesPlainHtmlUntouched() {
        let html = "<div><a href=\"https://example.com\"><img src=\"https://example.com/b.jpg\"></a></div>"
        #expect(BannerAdMarkupNormalizer.normalize(html) == html)
    }

    @Test func preservesFullHtmlDocumentWithoutDoubleWrapping() {
        let html = "<html><body><div>Ad</div><script src=\"https://track.example/imp\"></script></body></html>"
        let normalized = BannerAdMarkupNormalizer.normalize(html)
        #expect(normalized == html)
        #expect(normalized.components(separatedBy: "<html>").count - 1 == 1)
    }

    @Test func unwrapsEscapedJsonQuotesInAdmEnvelope() {
        let raw = #"document.write({ "adm": "<a href=\"https://click.example\">link</a>" });"#
        let normalized = BannerAdMarkupNormalizer.normalize(raw)
        #expect(!normalized.contains("\"adm\""))
        #expect(!normalized.contains("document.write("))
        #expect(normalized.contains("https://click.example"))
    }

    @Test func unwrapsSpacedAdmJsonEnvelope() {
        let raw = #"{ "adm" : "<div><img src=\"https://example.com/b.jpg\"></div>" }"#
        let normalized = BannerAdMarkupNormalizer.normalize(raw)
        #expect(!normalized.contains("\"adm\""))
        #expect(normalized.contains("example.com/b.jpg"))
    }

    @Test func unwrapsDocumentWriteWithTrailingImpressionScript() {
        let raw = #"document.write({ "adm": "<div id=\"wrapper\"><img src=\"https://example.com/a.jpg\"></div>" }<script src=\"https://track.example/impression\"></script>");"#
        let normalized = BannerAdMarkupNormalizer.normalize(raw)
        #expect(!normalized.contains("\"adm\""))
        #expect(normalized.contains("https://track.example/impression"))
    }

    @Test func extractRenderableMarkupFromNestedAdmJson() {
        let body = #"{"adm":"{ \"adm\" : \"<a href=\\\"https://click.example\\\">link</a>\" }"}"#
        let markup = BannerAdMarkupNormalizer.extractRenderableMarkup(from: body)
        #expect(markup?.contains("click.example") == true)
        #expect(markup?.contains("\"adm\"") == false)
    }

    @Test func unwrapsNestedAdmInsideDocumentWriteSpan() {
        let raw = #"document.write(<div><span id="banner_x">{"adm":"<a href=\"https://example.com\"><img src=\"https://example.com/b.jpg\"></a>"}</span><script src=\"https://track.example/impression\"></script></div>)"#
        let normalized = BannerAdMarkupNormalizer.normalize(raw)
        #expect(!normalized.contains("\"adm\""))
        #expect(normalized.contains("example.com/b.jpg"))
    }

    @Test func unwrapsNestedAdmWithUnescapedQuotesInSpan() {
        let raw = """
        document.write(<div><span id="banner_x">{
          "adm": "<div id="wrapper_abc"><a href="https://www.google.com"><img src="https://cdn.example/b.jpg"></a></div>"
        }
        </span></div>)
        """
        let normalized = BannerAdMarkupNormalizer.normalize(raw)
        #expect(!normalized.contains("\"adm\""))
        #expect(normalized.contains("wrapper_abc"))
        #expect(normalized.contains("cdn.example/b.jpg"))
    }
}
