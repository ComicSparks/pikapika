use serde_json::json;

use crate::pica::dto::{GameCommentChildrenPage, GameCommentPage, GameInfo, GamePage, Knight};

use super::call::{self, call};

pub async fn games(page: i64) -> Result<GamePage, String> {
    call::parse(&call("games", &page.to_string()).await?)
}

pub async fn game(game_id: String) -> Result<GameInfo, String> {
    call::parse(&call("game", &game_id).await?)
}

pub async fn game_comments(game_id: String, page: i64) -> Result<GameCommentPage, String> {
    call::parse(&call("gameComments", &json!({"gameId": game_id, "page": page}).to_string()).await?)
}

pub async fn post_game_comment(game_id: String, content: String) -> Result<(), String> {
    call::done(call("postGameComment", &json!({"gameId": game_id, "content": content}).to_string()).await)
}

pub async fn game_comment_children(game_id: String, comment_id: String, page: i64) -> Result<GameCommentChildrenPage, String> {
    call::parse(
        &call(
            "gameCommentChildren",
            &json!({"gameId": game_id, "commentId": comment_id, "page": page}).to_string(),
        )
        .await?,
    )
}

pub async fn switch_like_game_comment(comment_id: String, game_id: String) -> Result<(), String> {
    call::done(call("switchLikeGameComment", &json!({"commentId": comment_id, "gameId": game_id}).to_string()).await)
}

pub async fn post_game_child_comment(comment_id: String, content: String) -> Result<(), String> {
    call::done(call("postGameChildComment", &json!({"commentId": comment_id, "content": content}).to_string()).await)
}

pub async fn leaderboard_of_knight() -> Result<Vec<Knight>, String> {
    call::parse_vec(&call("leaderboardOfKnight", "").await?)
}

pub async fn download_game(url: String) -> Result<Vec<String>, String> {
    call::parse_vec(&call("downloadGame", &url).await?)
}
