import 'package:retrofit/retrofit.dart';
import 'package:dio/dio.dart';
import '../models/hierarchy_model.dart';
import '../models/portfolio_model.dart';
import '../models/program_model.dart';
import '../../domain/entities/hierarchy_item.dart';

part 'hierarchy_api_service.g.dart';

@RestApi()
abstract class HierarchyApiService {
  factory HierarchyApiService(Dio dio, {String baseUrl}) = _HierarchyApiService;

  // Hierarchy endpoints
  @GET('/api/v1/hierarchy/full')
  Future<HierarchyResponse> getFullHierarchy(
    @Query('include_archived') bool includeArchived,
  );

  @POST('/api/v1/hierarchy/move')
  Future<MoveItemResponse> moveItem(@Body() MoveItemRequest request);

  @POST('/api/v1/hierarchy/bulk-move')
  Future<BulkMoveResponse> bulkMoveItems(@Body() BulkMoveRequest request);

  @POST('/api/v1/hierarchy/bulk-delete')
  Future<BulkDeleteResponse> bulkDeleteItems(@Body() BulkDeleteRequest request);

  @POST('/api/v1/hierarchy/path')
  @DioResponseType(ResponseType.json)
  Future<HttpResponse<dynamic>> getHierarchyPath(@Body() Map<String, String> request);

  @GET('/api/v1/hierarchy/statistics/summary')
  @DioResponseType(ResponseType.json)
  Future<HttpResponse<dynamic>> getHierarchyStatistics();

  // Portfolio endpoints
  @GET('/api/v1/portfolios/')
  Future<List<PortfolioModel>> getPortfolios();

  @GET('/api/v1/portfolios/{id}')
  Future<PortfolioModel> getPortfolio(@Path('id') String portfolioId);

  @POST('/api/v1/portfolios/')
  Future<PortfolioModel> createPortfolio(@Body() Map<String, dynamic> request);

  @PUT('/api/v1/portfolios/{id}')
  Future<PortfolioModel> updatePortfolio(
    @Path('id') String portfolioId,
    @Body() Map<String, dynamic> request,
  );

  @DELETE('/api/v1/portfolios/{id}')
  @DioResponseType(ResponseType.json)
  Future<HttpResponse<dynamic>> deletePortfolio(
    @Path('id') String portfolioId,
    @Query('cascade_delete') bool cascadeDelete,
  );

  @GET('/api/v1/portfolios/{id}/deletion-impact')
  @DioResponseType(ResponseType.json)
  Future<HttpResponse<dynamic>> getPortfolioDeletionImpact(@Path('id') String portfolioId);

  @GET('/api/v1/portfolios/{id}/statistics')
  @DioResponseType(ResponseType.json)
  Future<HttpResponse<dynamic>> getPortfolioStatistics(@Path('id') String portfolioId);

  // Program endpoints
  @GET('/api/v1/programs/')
  Future<List<ProgramModel>> getPrograms(@Query('portfolio_id') String? portfolioId);

  @GET('/api/v1/programs/{id}')
  Future<ProgramModel> getProgram(@Path('id') String programId);

  @POST('/api/v1/programs/')
  Future<ProgramModel> createProgram(@Body() Map<String, dynamic> request);

  @PUT('/api/v1/programs/{id}')
  Future<ProgramModel> updateProgram(
    @Path('id') String programId,
    @Body() Map<String, dynamic> request,
  );

  @DELETE('/api/v1/programs/{id}')
  @DioResponseType(ResponseType.json)
  Future<HttpResponse<dynamic>> deleteProgram(
    @Path('id') String programId,
    @Query('cascade_delete') bool cascadeDelete,
  );

  @GET('/api/v1/programs/{id}/deletion-impact')
  @DioResponseType(ResponseType.json)
  Future<HttpResponse<dynamic>> getProgramDeletionImpact(@Path('id') String programId);

  @POST('/api/v1/programs/{id}/projects/move')
  @DioResponseType(ResponseType.json)
  Future<HttpResponse<dynamic>> moveProjectsToProgram(
    @Path('id') String programId,
    @Body() Map<String, dynamic> request,
  );

  @GET('/api/v1/programs/{id}/statistics')
  @DioResponseType(ResponseType.json)
  Future<HttpResponse<dynamic>> getProgramStatistics(@Path('id') String programId);
}