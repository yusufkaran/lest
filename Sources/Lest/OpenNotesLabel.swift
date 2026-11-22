/// A count of open notes in words: "1 open note", "3 open notes".
func openNotesLabel(_ count: Int) -> String {
    count == 1 ? "1 open note" : "\(count) open notes"
}
