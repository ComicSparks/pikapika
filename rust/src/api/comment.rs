use serde_json::json;

use crate::pica::dto::{CommentChildrenPage, CommentPage, MyCommentsPage};

use super::call::{self, call};

pub async fn comments(comic_id: String, page: i64) -> Result<CommentPage, String> {
    call::parse(&call("comments", &json!({"comicId": comic_id, "page": page}).to_string()).await?)
}

pub async fn comment_children(comic_id: String, comment_id: String, page: i64) -> Result<CommentChildrenPage, String> {
    call::parse(
        &call(
            "commentChildren",
            &json!({"comicId": comic_id, "commentId": comment_id, "page": page}).to_string(),
        )
        .await?,
    )
}

pub async fn post_comment(comic_id: String, content: String) -> Result<(), String> {
    call::done(call("postComment", &json!({"comicId": comic_id, "content": content}).to_string()).await)
}

pub async fn post_child_comment(comment_id: String, content: String) -> Result<(), String> {
    call::done(call("postChildComment", &json!({"commentId": comment_id, "content": content}).to_string()).await)
}

pub async fn switch_like_comment(comment_id: String, comic_id: String) -> Result<(), String> {
    call::done(call("switchLikeComment", &json!({"commentId": comment_id, "comicId": comic_id}).to_string()).await)
}

pub async fn my_comments(page: i64) -> Result<MyCommentsPage, String> {
    call::parse(&call("myComments", &page.to_string()).await?)
}
