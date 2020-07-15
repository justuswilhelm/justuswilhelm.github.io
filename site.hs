--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}

import           Data.Monoid (mappend)
import           Hakyll

import qualified Compilers   as C
import qualified Contexts    as Ctx

--------------------------------------------------------------------------------
main :: IO ()
main =
  hakyll $ do
    match "static/**" $ do
      route idRoute
      compile copyFileCompiler
    match "css/*" $ do
      route idRoute
      compile compressCssCompiler
    match "posts/*" $
      version "html" $ do
        route $ setExtension "html"
        compile $
          C.customPostPandocCompiler >>=
          loadAndApplyTemplate "templates/post.html" Ctx.postCtx >>=
          saveSnapshot "atom" >>=
          loadAndApplyTemplate "templates/default.html" Ctx.postCtx >>=
          saveSnapshot "content"
    match "posts/*" $
      version "pdf" $ do
        route $ setExtension "pdf"
      -- todo find a way we can pass the context here
        compile $ do
          body <- getResourceBody
          readPandocWith defaultHakyllReaderOptions body >>=
            C.relativizeUrlsWithCompiler "." >>=
            C.traverseRenderAll >>=
            C.writePandocLatexWith body
    match "posts/*" $
      version "teaser" $
      -- A little bit hacky, it generates a toc-html file which we don't need
      -- The only reason we create it is that we want to have some
      -- post link the we can direct to when showing this in the index
       do
        route $ setExtension "toc-html"
        compile $ C.customTeaserPandocCompiler >>= saveSnapshot "content"
    match "index.html" $ do
      route idRoute
      compile $ do
        posts <-
          recentFirst =<<
          loadAllSnapshots ("posts/*" .&&. hasVersion "teaser") "content"
        let indexCtx =
              listField "posts" Ctx.teaserCtx (return posts) `mappend`
              constField "title" "Home" `mappend`
              Ctx.pageDefaultContext
        getResourceBody >>= applyAsTemplate indexCtx >>=
          loadAndApplyTemplate "templates/default.html" indexCtx >>=
          C.replaceTocExtension >>=
          relativizeUrls
    match "templates/*" $ compile templateBodyCompiler
    match "robots.txt" $ do
      route idRoute
      compile $ getResourceBody >>= relativizeUrls
    create ["sitemap.xml"] $ do
      route idRoute
      compile $ do
        posts <-
          recentFirst =<<
          loadAllSnapshots ("posts/*" .&&. hasVersion "html") "content"
        -- TODO add pdf to sitempa
        -- postsPdf <-
        --   recentFirst =<<
        --   loadAll ("posts/*" .&&. hasVersion "pdf")
        -- we get this error right now
        -- [ERROR] Hakyll.Core.Compiler.Require.load:
        -- posts/2015-09-10-post.md (pdf) (snapshot _final) was found in the
        -- cache, but does not have the right type: expected [Char] but got
        -- ByteString
        pages <- loadAll "pages/*"
        let allPosts = return (pages ++ posts)
        let sitemapCtx =
              mconcat
                [ listField "entries" Ctx.postCtx allPosts
                , Ctx.pageDefaultContext
                ]
        makeItem "" >>= loadAndApplyTemplate "templates/sitemap.xml" sitemapCtx
    create ["atom.xml"] $ do
      route idRoute
      compile $ do
        let feedCtx = Ctx.postCtx `mappend` bodyField "description"
        posts <-
          recentFirst =<<
          loadAllSnapshots ("posts/*" .&&. hasVersion "html") "atom"
        renderAtom feedConfiguration feedCtx posts

--------------------------------------------------------------------------------
--- For RSS
feedConfiguration :: FeedConfiguration
feedConfiguration =
  FeedConfiguration
    { feedTitle = Ctx.pageTitle
    , feedDescription = "Articles about software and life"
    , feedAuthorName = Ctx.authorName
    , feedAuthorEmail = "hello@justus.pw"
    , feedRoot = Ctx.baseUrl
    }
