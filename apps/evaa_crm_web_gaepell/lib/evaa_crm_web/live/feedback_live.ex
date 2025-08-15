defmodule EvaaCrmWebGaepell.FeedbackLive do
  use EvaaCrmWebGaepell, :live_view
  alias EvaaCrmGaepell.{FeedbackReport, FeedbackComment, Repo}
  import Ecto.Query
  import Phoenix.Naming, only: [humanize: 1]
  import Phoenix.HTML.Form, only: [input_value: 2]

  @impl true
  def mount(_params, session, socket) do
    user_id = Map.get(session, "user_id")
    current_user = if user_id, do: Repo.get(EvaaCrmGaepell.User, user_id), else: nil
    socket =
      socket
      |> assign(:current_user, current_user)
      |> assign(:show_form, false)
      |> assign(:editing_id, nil)
      |> assign(:show_details, false)
      |> assign(:details_feedback, nil)
      |> assign(:comments, [])
      |> assign(:comment_changeset, nil)
      |> assign(:feedbacks, list_feedbacks())
      |> assign(:changeset, FeedbackReport.changeset(%FeedbackReport{}, %{}))
      |> allow_upload(:photo, accept: ~w(.jpg .jpeg .png), max_entries: 1)
    {:ok, socket}
  end

  defp list_feedbacks do
    Repo.all(from f in FeedbackReport, order_by: [desc: f.inserted_at])
  end

  @impl true
  def handle_event("new_feedback", _params, socket) do
    {:noreply, assign(socket, show_form: true, changeset: FeedbackReport.changeset(%FeedbackReport{}, %{}))}
  end

  @impl true
  def handle_event("cancel_feedback", _params, socket) do
    {:noreply, assign(socket, show_form: false)}
  end

  @impl true
  def handle_event("edit_feedback", %{"id" => id}, socket) do
    feedback = Repo.get!(FeedbackReport, id)
    changeset = FeedbackReport.changeset(feedback, %{})
    {:noreply, assign(socket, show_form: true, changeset: changeset, editing_id: id)}
  end

  @impl true
  def handle_event("delete_feedback", %{"id" => id}, socket) do
    feedback = Repo.get!(FeedbackReport, id)
    Repo.delete!(feedback)
    {:noreply, assign(socket, feedbacks: list_feedbacks())}
  end

  @impl true
  def handle_event("change_status", %{"id" => id, "status" => status}, socket) do
    feedback = Repo.get!(FeedbackReport, id)
    changeset = FeedbackReport.changeset(feedback, %{status: status})
    Repo.update!(changeset)
    Phoenix.PubSub.broadcast(EvaaCrmGaepell.PubSub, "feedbacks:updated", {:feedback_status_changed, feedback.id, status, feedback.description})
    {:noreply, assign(socket, feedbacks: list_feedbacks())}
  end

  @impl true
  def handle_event("save_feedback", %{"feedback_report" => params}, socket) do
    editing_id = socket.assigns[:editing_id]
    uploaded_files = consume_uploaded_entries(socket, :photo, fn %{path: path}, _entry ->
      dest = Path.join(["priv/static/uploads", Path.basename(path)])
      File.cp!(path, dest)
      ["/uploads/" <> Path.basename(dest)]
    end)
    photos = uploaded_files
    params = Map.put(params, "photos", photos)
    if editing_id do
      feedback = Repo.get!(FeedbackReport, editing_id)
      changeset = FeedbackReport.changeset(feedback, params)
      if changeset.valid? do
        Repo.update!(changeset)
        {:noreply, assign(socket, feedbacks: list_feedbacks(), show_form: false, changeset: FeedbackReport.changeset(%FeedbackReport{}, %{}), editing_id: nil)}
      else
        {:noreply, assign(socket, changeset: changeset)}
      end
    else
      changeset = FeedbackReport.changeset(%FeedbackReport{}, params)
      if changeset.valid? do
        Repo.insert!(changeset)
        {:noreply, assign(socket, feedbacks: list_feedbacks(), show_form: false, changeset: FeedbackReport.changeset(%FeedbackReport{}, %{}))}
      else
        {:noreply, assign(socket, changeset: changeset)}
      end
    end
  end

  @impl true
  def handle_event("show_details", %{"id" => id}, socket) do
    feedback = Repo.get!(FeedbackReport, id)
    comments = Repo.all(from c in FeedbackComment, where: c.feedback_report_id == ^id, order_by: [asc: c.inserted_at])
    {:noreply, assign(socket, show_details: true, details_feedback: feedback, comments: comments, comment_changeset: FeedbackComment.changeset(%FeedbackComment{}, %{}))}
  end

  @impl true
  def handle_event("close_details", _params, socket) do
    {:noreply, assign(socket, show_details: false, details_feedback: nil, comments: [], comment_changeset: nil)}
  end

  @impl true
  def handle_event("add_comment", %{"feedback_comment" => params}, socket) do
    feedback = socket.assigns.details_feedback
    email = socket.assigns.current_user && socket.assigns.current_user.email || "anonimo"
    author = email |> String.split("@") |> List.first()
    params = params
      |> Map.put("feedback_report_id", feedback.id)
      |> Map.put("author", author)
    changeset = FeedbackComment.changeset(%FeedbackComment{}, params)
    if changeset.valid? do
      Repo.insert!(changeset)
      comments = Repo.all(from c in FeedbackComment, where: c.feedback_report_id == ^feedback.id, order_by: [asc: c.inserted_at])
      feedback = Repo.get!(FeedbackReport, feedback.id)
      {:noreply, assign(socket, details_feedback: feedback, comments: comments, comment_changeset: FeedbackComment.changeset(%FeedbackComment{}, %{}))}
    else
      {:noreply, assign(socket, comment_changeset: changeset)}
    end
  end
end 