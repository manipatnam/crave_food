enum SearchSortOption {
  relevance('Relevance'),
  distance('Distance'),
  rating('Highest Rating'),
  name('Name A-Z'),
  popularity('Popularity');

  const SearchSortOption(this.label);
  final String label;
}