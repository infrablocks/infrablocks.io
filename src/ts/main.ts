import '../css/main.css'

enum Feedback {
  Helpful = "helpful",
  Unhelpful = "unhelpful"
}

function sendFeedbackEvent(feedback: Feedback) {
  gtag('event', 'docs_feedback', {
    'feedback': feedback
  })
}

function disableFeedbackWidget() {
  $(".feedback-button")
    .removeClass("bg-gray-200")
    .addClass("bg-gray-100")
  $(".feedback-button > a")
    .removeClass("text-gray-700")
    .addClass(["text-gray-400", "cursor-default"])
  $("#feedback-buttons")
    .off("click", "a#feedback-helpful")
    .off("click", "a#feedback-unhelpful")
}

function feedbackClickHandler(feedback: Feedback) {
  return function (event: Event) {
    event.preventDefault()
    sendFeedbackEvent(feedback)
    disableFeedbackWidget()
  }
}

$.when($.ready).then(function () {
  $("#feedback-buttons")
    .on("click",
      "a#feedback-helpful",
      feedbackClickHandler(Feedback.Helpful))
    .on("click",
      "a#feedback-unhelpful",
      feedbackClickHandler(Feedback.Unhelpful))
})
