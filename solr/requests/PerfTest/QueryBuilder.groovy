public class QueryBuilder {

	private static String FIELD_PRENAME = "search_";
	private static String NGRAM_SUFFIX = "_ngram";
	private static int NUM_FIELDS = 3;
	private String[] tokens = null;

	public QueryBuilder(String userInput){
		if (userInput == null)
			throw new GroovyRuntimeException("userInput is null");

		this.tokens = tokenize(userInput)
	}

	private static String[] tokenize(String userInput){
		String[] tokens = userInput.split(" ");

		for(String token in tokens){
			token = token.trim();
		}

		return tokens;
	}

	public String buildQuery(){
		String query = null;

		String[] fieldQueries = new String[QueryBuilder.NUM_FIELDS]
		for(int i=0; i<QueryBuilder.NUM_FIELDS; i++){
			fieldQueries[i] = buildQueryForField(i+1);
		}

		query = String.join(" OR ", fieldQueries);

		return query;
	}

	private String buildQueryForField(int fieldSuffix){
		String queryForField = null;

		String[] fragments = new String[tokens.length];
		for(int i=0; i<tokens.length; i++){
			fragments[i] = buildQueryFragment(fieldSuffix, tokens[i]);
		}

		queryForField = "(" +  String.join(" AND ", fragments) + ")";

		return queryForField;
	}

	private static String buildQueryFragment(int fieldSuffix, String token){

		String fieldNameExact = QueryBuilder.FIELD_PRENAME + Integer.toString(fieldSuffix);
		String fieldNameNgram = fieldNameExact + QueryBuilder.NGRAM_SUFFIX;

		int exactMatchWeight = (QueryBuilder.NUM_FIELDS - fieldSuffix + 1) * 2;
		int fuzzyMatchWeight = exactMatchWeight - 1;

		String queryFragment = "(" + fieldNameExact + ":" + token + "^" + exactMatchWeight + " OR " + fieldNameNgram + ":" + token + "^" + fuzzyMatchWeight + ")";

		return queryFragment;
	}
}

log.info("User query string: " + Parameters);

def qb = new QueryBuilder(Parameters);
def query = qb.buildQuery();

log.info("SOLR query string: " + query);

vars.put("SOLRQUERY", query);
